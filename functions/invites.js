/**
 * Invite Cleanup Cloud Function
 *
 * Scheduled function to remove expired invitations.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.database();

const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

/**
 * Runs every 24 hours and deletes invites that are unused and older than 7 days.
 */
exports.cleanupExpiredInvites = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const cutoff = Date.now() - INVITE_TTL_MS;

    const snap = await db.ref("/invites").once("value");
    if (!snap.exists()) return null;

    const updates = {};
    snap.forEach((child) => {
      const invite = child.val();
      if (!invite.used && invite.createdAt && invite.createdAt < cutoff) {
        updates[child.key] = null; // mark for deletion
      }
    });

    const count = Object.keys(updates).length;
    if (count === 0) {
      console.log("No expired invites to clean up");
      return null;
    }

    await db.ref("/invites").update(updates);
    console.log(`Deleted ${count} expired invite(s)`);
    return null;
  });
