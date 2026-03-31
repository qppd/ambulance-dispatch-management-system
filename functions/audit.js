/**
 * Audit Cloud Functions
 *
 * Logs role changes and other security-relevant events to /auditLog.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.database();

/**
 * When a user's role field changes, write an audit entry.
 */
exports.onUserRoleChanged = functions.database
  .ref("/users/{uid}/role")
  .onUpdate(async (change, context) => {
    const { uid } = context.params;
    const oldRole = change.before.val();
    const newRole = change.after.val();

    if (oldRole === newRole) return null;

    const entry = {
      type: "role_change",
      uid: uid,
      oldRole: oldRole,
      newRole: newRole,
      timestamp: admin.database.ServerValue.TIMESTAMP,
      changedBy: context.auth ? context.auth.uid : "system",
    };

    await db.ref("/auditLog").push(entry);
    console.log(`Audit: ${uid} role changed ${oldRole} -> ${newRole}`);
    return null;
  });
