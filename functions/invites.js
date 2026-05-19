/**
 * Invite Cleanup Cloud Function (v2)
 *
 * Scheduled function to remove expired invitations.
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.database();

const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

/**
 * Runs every 24 hours and deletes invites that are unused and older than 7 days.
 */
exports.cleanupExpiredInvites = onSchedule(
  { schedule: "every 24 hours" },
  async () => {
    const cutoff = Date.now() - INVITE_TTL_MS;

    const snap = await db.ref("/invites").once("value");
    if (!snap.exists()) return null;

    const updates = {};
    snap.forEach((child) => {
      const invite = child.val();
      if (!invite.used && invite.createdAt && invite.createdAt < cutoff) {
        updates[child.key] = null;
      }
    });

    const count = Object.keys(updates).length;
    if (count === 0) {
      logger.info("No expired invites to clean up");
      return null;
    }

    await db.ref("/invites").update(updates);
    logger.info(`Deleted ${count} expired invite(s)`);
    return null;
  }
);