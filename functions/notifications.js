/**
 * Notification Cloud Functions (v2)
 *
 * Sends push notifications via Firebase Cloud Messaging (FCM).
 */

const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.database();

/**
 * When a unit's status changes to 'dispatched', send a push notification
 * to the assigned driver — but ONLY if they have incidentUpdates enabled
 * in /users/{uid}/notificationPrefs.incidentUpdates.
 *
 * We listen on `dispatched` (not `enRoute`) because the auto-dispatch
 * Cloud Function (`onIncidentCreated`) writes `status → dispatched` before
 * the driver manually taps "En Route", so a `enRoute` trigger would miss
 * auto-dispatches entirely.
 */
exports.onUnitDispatched = onValueWritten(
  { ref: "/units/{municipalityId}/{unitId}/status" },
  async (event) => {
    const { municipalityId, unitId } = event.params;
    const newStatus = event.data.after.val();

    // Only fire on the transition TO dispatched — not on manual enRoute by crew.
    if (newStatus !== "dispatched") return null;

    // Get the unit to find the driver and current incident
    const unitSnap = await db
      .ref(`/units/${municipalityId}/${unitId}`)
      .once("value");
    const unit = unitSnap.val();
    if (!unit || !unit.assignedDriverId) return null;

    const driverId = unit.assignedDriverId;

    // Get driver's profile including notification preferences
    const driverSnap = await db
      .ref(`/users/${driverId}`)
      .once("value");
    const driver = driverSnap.val();
    if (!driver || !driver.fcmToken) {
      logger.info(`Driver ${driverId} has no FCM token — skipping push`);
      return null;
    }

    // Respect per-driver notification preferences stored at /users/{uid}/notificationPrefs
    const prefs = driver.notificationPrefs;
    if (prefs && prefs.incidentUpdates === false) {
      logger.info(`Driver ${driverId} has disabled incident updates — skipping push`);
      return null;
    }

    // Get incident details
    let incidentDesc = "New dispatch assignment";
    if (unit.currentIncidentId) {
      const incSnap = await db
        .ref(`/incidents/${municipalityId}/${unit.currentIncidentId}`)
        .once("value");
      const inc = incSnap.val();
      if (inc) {
        incidentDesc = inc.description || incidentDesc;
      }
    }

    // Send FCM notification
    const message = {
      token: driver.fcmToken,
      notification: {
        title: "New Dispatch — Respond Now",
        body: `${unit.callSign}: ${incidentDesc}`,
      },
      data: {
        type: "dispatch",
        unitId: unitId,
        municipalityId: municipalityId,
        incidentId: unit.currentIncidentId || "",
      },
      android: {
        priority: "high",
        notification: { channelId: "dispatch_alerts" },
      },
    };

    try {
      await admin.messaging().send(message);
      logger.info(`Push sent to driver ${driverId}`);
    } catch (err) {
      logger.error("FCM send error:", err);
    }
    return null;
  }
);