/**
 * User Profile Cloud Functions (v2)
 *
 * Keeps the /municipality_users/{municipalityId}/{uid} mirror in sync with
 * /users/{uid}.
 *
 * Why a mirror exists:
 *   Firebase Realtime Database rules authorize a query at the queried
 *   location only — they cannot filter query results. Municipal admins need
 *   a municipality-scoped list of their staff (staff directory, dashboard
 *   staff counts, available-driver picker). Granting them `.read` on the
 *   whole /users collection would expose every citizen's and every other
 *   municipality's personal data (email, phone). This mirror is written here
 *   with the admin SDK (bypasses security rules) and is read-only for
 *   clients, with reads scoped to the owning municipality by
 *   database.rules.json.
 *
 * Sync points (all writes to /users/{uid} fire this trigger):
 *   - registration (create)        -> insert mirror entry
 *   - sign-in lastLoginAt update   -> refresh mirror entry
 *   - approval/deactivation/role   -> refresh mirror entry
 *   - fcm token save               -> refresh (token stripped below)
 *   - profile edits                -> refresh mirror entry
 *   - account deletion             -> remove mirror entry
 *   - municipality change          -> move mirror entry (remove old + write new)
 */

const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.database();

exports.onUserProfileWritten = onValueWritten(
  { ref: "/users/{uid}" },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data.after.val();
    const before = event.data.before.val();

    const beforeMuni = before ? before.municipalityId || null : null;
    const afterMuni = after ? after.municipalityId || null : null;

    const updates = {};

    // Remove the stale entry when a user is deleted or moves municipality.
    if (beforeMuni && beforeMuni !== afterMuni) {
      updates[`/municipality_users/${beforeMuni}/${uid}`] = null;
    }

    if (after && afterMuni) {
      const mirror = { ...after, id: uid };
      // Push tokens must not leak to municipal admin clients.
      delete mirror.fcmToken;
      updates[`/municipality_users/${afterMuni}/${uid}`] = mirror;
    }

    if (Object.keys(updates).length === 0) {
      return null;
    }

    await db.ref().update(updates);
    logger.info(`municipality_users mirror synced for ${uid} -> ${afterMuni || "(removed)"}`);
    return null;
  }
);
