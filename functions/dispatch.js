/**
 * Dispatch Cloud Functions (v2)
 *
 * Handles auto-dispatch and incident lifecycle events.
 * Uses multi-path transactions to prevent double-assignment
 * of ambulance units in concurrent incident scenarios.
 */

const { onValueCreated, onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

const db = admin.database();

/**
 * Compute the great-circle distance between two points using the Haversine
 * formula. Returns distance in kilometres.
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (v) => (v * Math.PI) / 180;
  const R = 6371; // Earth radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Validate that a value is a valid latitude.
 */
function isValidLatitude(v) {
  return typeof v === "number" && !Number.isNaN(v) && v >= -90 && v <= 90;
}

/**
 * Validate that a value is a valid longitude.
 */
function isValidLongitude(v) {
  return typeof v === "number" && !Number.isNaN(v) && v >= -180 && v <= 180;
}

/**
 * Atomically claim a unit for an incident using a transaction on the unit node.
 *
 * Reads the current unit status under a transaction. If the unit is still
 * "available", claims it (sets status → "enRoute"). Otherwise the transaction
 * aborts and the caller must try the next candidate.
 */
async function claimUnitInTransaction(municipalityId, unitId, incidentId) {
  const unitRef = db.ref(`/units/${municipalityId}/${unitId}`);

  try {
    const result = await unitRef.transaction(
      (currentData) => {
        if (currentData === null) {
          return; // unit deleted — abort
        }
        if (currentData.status !== "available") {
          return; // already taken — abort
        }
        currentData.status = "enRoute";
        currentData.currentIncidentId = incidentId;
        return currentData;
      },
      (error, committed, snapshot) => {
        if (error) {
          logger.error(`Transaction error for unit ${unitId}:`, error);
        }
      },
      false,
    );

    if (result.committed && result.snapshot.val()) {
      return { claimed: true, unit: result.snapshot.val() };
    }
    return { claimed: false };
  } catch (err) {
    logger.error(`Transaction failed for unit ${unitId}:`, err);
    return { claimed: false };
  }
}

/**
 * Triggered when a new incident is created.
 * If auto-dispatch is enabled, finds the nearest available unit and assigns it
 * using an atomic transaction to prevent double-assignment.
 */
exports.onIncidentCreated = onValueCreated(
  { ref: "/incidents/{municipalityId}/{incidentId}" },
  async (event) => {
    const { municipalityId, incidentId } = event.params;
    const incident = event.data.val();

    // Input validation — reject malformed incident data
    if (!incident) {
      logger.error("onIncidentCreated: incident snapshot is null");
      return null;
    }
    if (
      !isValidLatitude(incident.latitude) ||
      !isValidLongitude(incident.longitude)
    ) {
      logger.error(
        `onIncidentCreated: invalid coordinates (lat=${incident.latitude}, lng=${incident.longitude}) for incident ${incidentId}`
      );
      await event.data.ref.update({
        autoDispatchError:
          "Invalid coordinates — cannot auto-dispatch to this location",
      });
      return null;
    }

    // Check if auto-dispatch is enabled
    const configSnap = await db.ref("/systemConfig").once("value");
    const config = configSnap.val() || {};
    if (!config.autoDispatchEnabled) {
      logger.info("Auto-dispatch disabled — skipping.");
      return null;
    }

    // Find available units in the municipality
    const unitsSnap = await db
      .ref(`/units/${municipalityId}`)
      .orderByChild("status")
      .equalTo("available")
      .once("value");

    const units = unitsSnap.val();
    if (!units) {
      logger.info(`No available units in ${municipalityId}`);
      return null;
    }

    // Sort available units by haversine distance to the incident
    const incLat = incident.latitude;
    const incLon = incident.longitude;
    const candidates = [];

    for (const [id, u] of Object.entries(units)) {
      if (
        u.latitude == null ||
        u.longitude == null ||
        !isValidLatitude(u.latitude) ||
        !isValidLongitude(u.longitude)
      ) {
        continue;
      }
      const dist = haversineKm(incLat, incLon, u.latitude, u.longitude);
      candidates.push({ id, unit: u, distance: dist });
    }

    candidates.sort((a, b) => a.distance - b.distance);

    if (candidates.length === 0) {
      const keys = Object.keys(units);
      if (keys.length === 0) return null;
      candidates.push({
        id: keys[0],
        unit: units[keys[0]],
        distance: Infinity,
      });
      logger.info("No unit coordinates — falling back to first available unit");
    }

    // Atomic claim: try each candidate in order until one succeeds
    let claimed = false;
    let claimedUnit = null;
    let claimedId = null;

    for (const candidate of candidates) {
      const result = await claimUnitInTransaction(
        municipalityId,
        candidate.id,
        incidentId
      );
      if (result.claimed) {
        claimed = true;
        claimedUnit = result.unit;
        claimedId = candidate.id;
        logger.info(
          `Claimed unit ${claimedId} (${candidate.distance.toFixed(1)} km) via transaction`
        );
        break;
      }
      logger.info(`Unit ${candidate.id} already taken — trying next candidate`);
    }

    if (!claimed) {
      logger.error(
        `onIncidentCreated: ALL available units were taken before dispatch could complete for incident ${incidentId}`
      );
      await event.data.ref.update({
        autoDispatchError:
          "All available units were taken — manual dispatch required",
      });
      return null;
    }

    // Update incident with dispatch details
    const updates = {};
    updates[`/incidents/${municipalityId}/${incidentId}/assignedUnitId`] =
      claimedId;
    updates[`/incidents/${municipalityId}/${incidentId}/status`] = "dispatched";
    updates[`/incidents/${municipalityId}/${incidentId}/dispatchedAt`] =
      new Date().toISOString();

    await db.ref().update(updates);

    logger.info(
      `Auto-dispatched unit ${claimedUnit.callSign || claimedId} (${candidates.find((c) => c.id === claimedId)?.distance.toFixed(1) || "?"} km) to incident ${incidentId}`
    );
    return null;
  }
);

/**
 * Triggered when an incident status changes.
 * When resolved, frees the assigned unit and records response metrics.
 *
 * Added guard: only frees the unit if it's still assigned to this incident,
 * preventing race conditions where a unit was reassigned.
 */
exports.onIncidentStatusChanged = onValueWritten(
  { ref: "/incidents/{municipalityId}/{incidentId}/status" },
  async (event) => {
    const { municipalityId, incidentId } = event.params;
    const newStatus = event.data.after.val();

    if (newStatus !== "resolved") return null;

    // Get the full incident to find the assigned unit
    const incSnap = await db
      .ref(`/incidents/${municipalityId}/${incidentId}`)
      .once("value");
    const incident = incSnap.val();
    if (!incident || !incident.assignedUnitId) return null;

    const unitId = incident.assignedUnitId;

    // Guard: check that the unit is still assigned to this incident
    const unitSnap = await db
      .ref(`/units/${municipalityId}/${unitId}`)
      .once("value");
    const unit = unitSnap.val();

    if (!unit) {
      logger.info(`Unit ${unitId} no longer exists — skipping free`);
      return null;
    }

    if (unit.currentIncidentId !== incidentId) {
      logger.info(
        `Unit ${unitId} is now assigned to incident ${unit.currentIncidentId} instead of ${incidentId} — not freeing`
      );
      return null;
    }

    // Free the unit
    await db
      .ref(`/units/${municipalityId}/${unitId}`)
      .update({
        status: "available",
        currentIncidentId: null,
      });

    // Record resolution timestamp
    await db
      .ref(`/incidents/${municipalityId}/${incidentId}/resolvedAt`)
      .set(new Date().toISOString());

    logger.info(`Incident ${incidentId} resolved — unit ${unitId} freed`);
    return null;
  }
);