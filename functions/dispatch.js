/**
 * Dispatch Cloud Functions
 *
 * Handles auto-dispatch and incident lifecycle events.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

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
 * Triggered when a new incident is created.
 * If auto-dispatch is enabled, finds the nearest available unit and assigns it.
 */
exports.onIncidentCreated = functions.database
  .ref("/incidents/{municipalityId}/{incidentId}")
  .onCreate(async (snapshot, context) => {
    const { municipalityId, incidentId } = context.params;
    const incident = snapshot.val();

    // Check if auto-dispatch is enabled
    const configSnap = await db.ref("/systemConfig").once("value");
    const config = configSnap.val() || {};
    if (!config.autoDispatchEnabled) {
      console.log("Auto-dispatch disabled — skipping.");
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
      console.log(`No available units in ${municipalityId}`);
      return null;
    }

    // Find the nearest unit by haversine distance to the incident location
    const incLat = incident.latitude;
    const incLon = incident.longitude;
    let nearestId = null;
    let nearestDist = Infinity;

    for (const [id, u] of Object.entries(units)) {
      if (u.latitude == null || u.longitude == null) continue;
      const dist = haversineKm(incLat, incLon, u.latitude, u.longitude);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestId = id;
      }
    }

    // Fall back to first key if no unit has coordinates
    if (!nearestId) {
      nearestId = Object.keys(units)[0];
      console.log("No unit coordinates — falling back to first available unit");
    }

    const unit = units[nearestId];

    // Assign the unit to the incident
    const updates = {};
    updates[`/incidents/${municipalityId}/${incidentId}/assignedUnitId`] =
      nearestId;
    updates[`/incidents/${municipalityId}/${incidentId}/status`] = "dispatched";
    updates[`/incidents/${municipalityId}/${incidentId}/dispatchedAt`] =
      new Date().toISOString();
    updates[`/units/${municipalityId}/${nearestId}/status`] = "enRoute";
    updates[`/units/${municipalityId}/${nearestId}/currentIncidentId`] =
      incidentId;

    await db.ref().update(updates);
    console.log(
      `Auto-dispatched unit ${unit.callSign} (${nearestDist.toFixed(1)} km) to incident ${incidentId}`
    );
    return null;
  });

/**
 * Triggered when an incident status changes.
 * When resolved, frees the assigned unit and records response metrics.
 */
exports.onIncidentStatusChanged = functions.database
  .ref("/incidents/{municipalityId}/{incidentId}/status")
  .onUpdate(async (change, context) => {
    const { municipalityId, incidentId } = context.params;
    const newStatus = change.after.val();

    if (newStatus !== "resolved") return null;

    // Get the full incident to find the assigned unit
    const incSnap = await db
      .ref(`/incidents/${municipalityId}/${incidentId}`)
      .once("value");
    const incident = incSnap.val();
    if (!incident || !incident.assignedUnitId) return null;

    // Free the unit
    await db
      .ref(`/units/${municipalityId}/${incident.assignedUnitId}`)
      .update({
        status: "available",
        currentIncidentId: null,
      });

    // Record resolution timestamp
    await db
      .ref(`/incidents/${municipalityId}/${incidentId}/resolvedAt`)
      .set(new Date().toISOString());

    console.log(
      `Incident ${incidentId} resolved — unit ${incident.assignedUnitId} freed`
    );
    return null;
  });
