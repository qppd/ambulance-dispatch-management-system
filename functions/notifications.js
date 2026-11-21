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
 * Send push notification to the assigned driver when an incident is
 * dispatched (auto or manual). Triggers on /incidents/{municipalityId}/{incidentId}/status
 * changing to 'dispatched' — matching the same event as the admin
 * notification in incident_notifications.js, so both are sent from one write.
 */
exports.onIncidentDispatched = onValueWritten(
  { ref: "/incidents/{municipalityId}/{incidentId}/status" },
  async (event) => {
    const { municipalityId, incidentId } = event.params;
    const newStatus = event.data.after.val();

    // Only fire when the incident status transitions TO dispatched
    if (newStatus !== "dispatched") return null;

    // Get full incident to find assigned unit/driver
    const incSnap = await db
      .ref(`/incidents/${municipalityId}/${incidentId}`)
      .once("value");
    const incident = incSnap.val();
    if (!incident || !incident.assignedUnitId) {
      logger.info(`Incident ${incidentId} has no assigned unit — skipping driver notification`);
      return null;
    }

    // Get the unit to find the driver
    const unitSnap = await db
      .ref(`/units/${municipalityId}/${incident.assignedUnitId}`)
      .once("value");
    const unit = unitSnap.val();
    if (!unit || !unit.assignedDriverId) {
      logger.info(`Unit ${incident.assignedUnitId} has no assigned driver — skipping`);
      return null;
    }

    const driverId = unit.assignedDriverId;

    // Get driver's profile including FCM token
    const driverSnap = await db.ref(`/users/${driverId}`).once("value");
    const driver = driverSnap.val();
    if (!driver || !driver.fcmToken) {
      logger.info(`Driver ${driverId} has no FCM token — skipping push`);
      return null;
    }

    // Respect per-driver notification preferences
    const prefs = driver.notificationPrefs;
    if (prefs && prefs.incidentUpdates === false) {
      logger.info(`Driver ${driverId} has disabled incident updates — skipping push`);
      return null;
    }

    // Get call sign
    const callSign = unit.callSign || incident.assignedUnitCallSign || incident.assignedUnitId;

    // Build notification body
    const description = incident.description || "New dispatch assignment";
    const notifyBody = `${callSign}: ${description}`;

    // Send FCM notification
    const message = {
      token: driver.fcmToken,
      notification: {
        title: "🚨 New Dispatch — Respond Now",
        body: notifyBody,
      },
      data: {
        type: "dispatch",
        unitId: incident.assignedUnitId,
        municipalityId: municipalityId,
        incidentId: incidentId,
      },
      android: {
        priority: "high",
        notification: { channelId: "incident_alerts" },
      },
    };

    try {
      await admin.messaging().send(message);
      logger.info(`Push sent to driver ${driverId} for incident ${incidentId}`);
    } catch (err) {
      logger.error("FCM send error:", err);
    }

    return null;
  },
);
