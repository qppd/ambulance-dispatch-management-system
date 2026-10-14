/**
 * Audit Cloud Functions (v2)
 *
 * Logs role changes and other security-relevant events to /auditLog.
 */

const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.database();

/**
 * When a user's role field changes, write an audit entry.
 */
exports.onUserRoleChanged = onValueWritten(
  { ref: "/users/{uid}/role" },
  async (event) => {
    const { uid } = event.params;
    const oldRole = event.data.before.val();
    const newRole = event.data.after.val();

    if (oldRole === newRole) return null;

    const entry = {
      type: "role_change",
      uid: uid,
      oldRole: oldRole,
      newRole: newRole,
      // ISO-8601 UTC string: the app's AuditEntry.fromJson parses it with
      // DateTime.parse(json['timestamp'] as String) on every auditLog entry,
      // and admin.database.ServerValue is undefined under firebase-admin v13
      // (it would crash this function on every /users write).
      timestamp: new Date().toISOString(),
      changedBy: event.auth ? event.auth.uid : "system",
    };

    await db.ref("/auditLog").push(entry);
    logger.info(`Audit: ${uid} role changed ${oldRole} -> ${newRole}`);
    return null;
  }
);