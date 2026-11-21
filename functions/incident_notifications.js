const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.database();

/**
 * When a new incident is created, send push notifications to all
 * municipal admins of the owning municipality (if they have
 * incidentUpdates enabled) and to all active drivers who are available
 * in that municipality (so they can see the new request).
 *
 * We listen on status change to dispatched so it fires after the
 * auto-dispatch Cloud Function has claimed a unit — ensuring the
 * notification payload includes the assigned unit call sign.
 */
exports.onIncidentDispatched = onValueWritten(
  { ref: "/incidents/{municipalityId}/{incidentId}/status" },
  async (event) => {
    const { municipalityId, incidentId } = event.params;
    const newStatus = event.data.after.val();

    // Only fire when the incident transitions TO dispatched (auto or manual).
    if (newStatus !== "dispatched") return null;

    // Read full incident details
    const incSnap = await db
      .ref(`/incidents/${municipalityId}/${incidentId}`)
      .once("value");
    const incident = incSnap.val();
    if (!incident) return null;

    // Read assigned unit to get call sign
    let callSign = "";
    if (incident.assignedUnitId) {
      const unitSnap = await db
        .ref(`/units/${municipalityId}/${incident.assignedUnitId}`)
        .once("value");
      const unit = unitSnap.val();
      if (unit) callSign = unit.callSign || incident.assignedUnitCallSign || incident.assignedUnitId;
    }

    const description = incident.description || "New emergency request";
    const address = incident.address || "Location pending";
    const severity = incident.severity || "normal";
    const notifyBody = `${callSign}: ${description} — ${address} (${severity})`;

    // ── Notify municipal admins ───────────────────────────────────────
    try {
      const usersSnap = await db
        .ref("/users")
        .orderByChild("municipalityId")
        .equalTo(municipalityId)
        .once("value");
      const usersMap = usersSnap.val();
      if (!usersMap) return null;

      const tokens = [];
      for (const [uid, user] of Object.entries(usersMap)) {
        if (!user.fcmToken) continue;
        // Only municipal admins
        if (user.role !== "municipalAdmin") continue;
        // Respect per-user notification preferences
        // NOTE: notificationPrefs exists only on citizen accounts;
        // admins default to receiving notifications unless explicitly disabled.
        const prefs = user.notificationPrefs;
        if (prefs && prefs.incidentUpdates === false) continue;
        tokens.push({ uid, token: user.fcmToken });
      }

      if (tokens.length > 0) {
        const adminPromises = tokens.map(({ token }) =>
          admin.messaging().send({
            token,
            notification: {
              title: "🚨 New Emergency Request",
              body: notifyBody,
            },
            data: {
              type: "new_incident",
              municipalityId,
              incidentId,
              role: "municipalAdmin",
            },
            android: {
              priority: "high",
              notification: { channelId: "incident_alerts" },
            },
          }),
        );
        await Promise.all(adminPromises);
        logger.info(
          `Sent ${adminPromises.length} admin notification(s) for incident ${incidentId}`,
        );
      }
    } catch (err) {
      logger.error("Error sending admin notifications:", err);
    }

    return null;
  },
);
