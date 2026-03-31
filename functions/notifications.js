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

/**
 * When an incident status changes to 'transporting' with a destination
 * hospital, notify the hospital staff.
 */
exports.onPatientEnRoute = functions.database
  .ref("/incidents/{municipalityId}/{incidentId}/status")
  .onUpdate(async (change, context) => {
    const { municipalityId, incidentId } = context.params;
    const newStatus = change.after.val();

    if (newStatus !== "transporting") return null;

    const incSnap = await db
      .ref(`/incidents/${municipalityId}/${incidentId}`)
      .once("value");
    const incident = incSnap.val();
    if (!incident || !incident.destinationHospitalId) return null;

    // Find hospital staff users with FCM tokens
    const usersSnap = await db
      .ref("/users")
      .orderByChild("hospitalId")
      .equalTo(incident.destinationHospitalId)
      .once("value");

    const staff = usersSnap.val();
    if (!staff) return null;

    const tokens = Object.values(staff)
      .filter((u) => u.fcmToken && u.role === "hospitalStaff")
      .map((u) => u.fcmToken);

    if (tokens.length === 0) return null;

    const message = {
      notification: {
        title: "Incoming Patient",
        body: `Ambulance en route — ${incident.severity || "urgent"} severity`,
      },
      data: {
        type: "incoming_patient",
        incidentId: incidentId,
        municipalityId: municipalityId,
      },
      android: {
        priority: "high",
        notification: { channelId: "hospital_alerts" },
      },
    };

    // Send to each token individually (sendEachForMulticast not always available)
    const results = await Promise.allSettled(
      tokens.map((token) => admin.messaging().send({ ...message, token }))
    );
    const sent = results.filter((r) => r.status === "fulfilled").length;
    console.log(`Notified ${sent}/${tokens.length} hospital staff`);

    return null;
  });
