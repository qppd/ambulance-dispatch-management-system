/**
 * Notification Cloud Functions
 *
 * Sends push notifications via Firebase Cloud Messaging (FCM).
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.database();

/**
 * When a unit's status changes to 'enRoute', send a push notification
 * to the assigned driver.
 */
exports.onUnitDispatched = functions.database
  .ref("/units/{municipalityId}/{unitId}/status")
  .onUpdate(async (change, context) => {
    const { municipalityId, unitId } = context.params;
    const newStatus = change.after.val();

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
      console.log(`Driver ${unit.assignedDriverId} has no FCM token`);
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
      console.log(`Push sent to driver ${unit.assignedDriverId}`);
    } catch (err) {
      console.error("FCM send error:", err);
    }
    return null;
  });

