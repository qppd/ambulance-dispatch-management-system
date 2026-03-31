/**
 * Dispatch Cloud Functions
 *
 * Handles auto-dispatch and incident lifecycle events.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.database();

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

    // Pick the first available unit (TODO: compute nearest by haversine)
    const unitId = Object.keys(units)[0];
    const unit = units[unitId];

    // Assign the unit to the incident
    const updates = {};
    updates[`/incidents/${municipalityId}/${incidentId}/assignedUnitId`] =
      unitId;
    updates[`/incidents/${municipalityId}/${incidentId}/status`] = "dispatched";
    updates[`/incidents/${municipalityId}/${incidentId}/dispatchedAt`] =
      new Date().toISOString();
    updates[`/units/${municipalityId}/${unitId}/status`] = "enRoute";
    updates[`/units/${municipalityId}/${unitId}/currentIncidentId`] =
      incidentId;

    await db.ref().update(updates);
    console.log(
      `Auto-dispatched unit ${unit.callSign} to incident ${incidentId}`
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
