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
 * When a unit's status changes to 'enRoute', send a push notification
 * to the assigned driver.
 */
exports.onUnitDispatched = onValueWritten(
  { ref: "/units/{municipalityId}/{unitId}/status" },
  async (event) => {
    const { municipalityId, unitId } = event.params;
    const newStatus = event.data.after.val();

    if (newStatus !== "enRoute") return null;

    // Get the unit to find the driver
    const unitSnap = await db
      .ref(`/units/${municipalityId}/${unitId}`)
      .once("value");
    const unit = unitSnap.val();
    if (!unit || !unit.assignedDriverId) return null;

    // Get driver's FCM token
    const driverSnap = await db
      .ref(`/users/${unit.assignedDriverId}`)
      .once("value");
    const driver = driverSnap.val();
    if (!driver || !driver.fcmToken) {
      logger.info(`Driver ${unit.assignedDriverId} has no FCM token`);
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
      logger.info(`Push sent to driver ${unit.assignedDriverId}`);
    } catch (err) {
      logger.error("FCM send error:", err);
    }
    return null;
  }
);