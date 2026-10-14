/**
 * /municipality_users mirror — Cloud Function integration test.
 *
 * Verifies that the `onUserProfileWritten` Cloud Function (functions/users.js)
 * keeps the municipality-scoped staff directory in sync with /users, which is
 * what lets municipal admin screens (staff directory, dashboard staff counts,
 * available-driver picker) work under municipality-scoped rules.
 *
 * Run from the repository root (use --test-concurrency=1 when combining with
 * rules.test.mjs; both files clear the same emulator DB in beforeEach):
 *   firebase emulators:exec --only database,functions --project demo-adms \
 *     "node --test --test-concurrency=1 tests/database-rules/mirror-sync.test.mjs"
 */

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const RULES_URL = new URL('../../source/flutter/adms/database.rules.json', import.meta.url);

const T0 = '2026-01-01T00:00:00.000';
const T1 = '2026-01-01T00:05:00.000';

let testEnv;

function dbAs(uid) {
  if (uid === null || uid === undefined) {
    return testEnv.unauthenticatedContext().database();
  }
  return testEnv.authenticatedContext(uid).database();
}

async function seed(ctx) {
  await ctx.database().ref().update({
    'municipalities/muniA': {
      id: 'muniA', name: 'Alpha City', province: 'Alpha', region: 'R', createdAt: T0,
    },
    'users/adminA': {
      id: 'adminA', email: 'admina@example.org', firstName: 'Admin', lastName: 'A',
      role: 'municipalAdmin', municipalityId: 'muniA', isApproved: true, isActive: true,
      isVerified: true, createdAt: T0,
    },
  });
}

/** Poll until fn() is truthy (Cloud Functions are asynchronous). */
async function waitFor(fn, { timeoutMs = 15000, label = 'condition' } = {}) {
  const start = Date.now();
  let last;
  while (Date.now() - start < timeoutMs) {
    try {
      last = await fn();
      if (last) return last;
    } catch (e) {
      last = undefined;
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`Timed out waiting for ${label} (last value: ${JSON.stringify(last)})`);
}

/**
 * Read a path with security rules bypassed.
 *
 * `withSecurityRulesDisabled` awaits the callback but returns `undefined`
 * (see @firebase/rules-unit-testing dist source), so the snapshot has to be
 * captured from inside the callback — returning it directly would resolve to
 * `undefined` and throw on `.val()`.
 */
async function adminRead(path) {
  let snapshot;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    snapshot = await ctx.database().ref(path).get();
  });
  return snapshot;
}

async function mirrorEntry(uid) {
  const snap = await adminRead('municipality_users');
  const all = snap.val() || {};
  for (const muni of Object.values(all)) {
    if (muni && muni[uid]) return muni[uid];
  }
  return null;
}

/**
 * Create a privileged (approval-required) user the way the app actually does:
 * self-registration writes the record with `isApproved: false`, then a
 * municipal admin approves it. Writing `isApproved: true` as the user
 * themself is denied by database.rules.json, by design.
 */
async function registerAndApprove(uid, record) {
  await dbAs(uid).ref(`users/${uid}`).set({ ...record, isApproved: false });
  await dbAs('adminA').ref(`users/${uid}/isApproved`).set(true);
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-adms',
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: readFileSync(RULES_URL, 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearDatabase();
  await testEnv.withSecurityRulesDisabled(seed);
});

test('registration writes /users and the mirror appears with the same fields', async () => {
  const record = {
    id: 'crew1', email: 'crew1@example.org', firstName: 'Crew', lastName: 'One',
    phoneNumber: '+63000000001', role: 'driver', municipalityId: 'muniA',
    municipalityName: 'Alpha City', isVerified: false, isActive: true,
    isApproved: false, createdAt: T0,
  };
  await dbAs('crew1').ref('users/crew1').set(record);

  const entry = await waitFor(() => mirrorEntry('crew1'), { label: 'mirror entry for crew1' });
  assert.equal(entry.id, 'crew1');
  assert.equal(entry.role, 'driver');
  assert.equal(entry.municipalityId, 'muniA');
  assert.equal(entry.isApproved, false);
  assert.equal(entry.email, 'crew1@example.org');
});

test('approval and profile edits propagate to the mirror', async () => {
  const record = {
    id: 'crew2', email: 'crew2@example.org', firstName: 'Crew', lastName: 'Two',
    role: 'driver', municipalityId: 'muniA', isApproved: false, isActive: true,
    isVerified: false, createdAt: T0,
  };
  await dbAs('crew2').ref('users/crew2').set(record);
  await waitFor(() => mirrorEntry('crew2'), { label: 'mirror entry for crew2' });

  // municipal admin approves (rules-tested separately)
  await dbAs('adminA').ref('users/crew2/isApproved').set(true);
  await waitFor(
    async () => (await mirrorEntry('crew2'))?.isApproved === true,
    { label: 'approval propagated' }
  );

  // the user edits their own profile
  await dbAs('crew2').ref('users/crew2/firstName').set('Renamed');
  await waitFor(
    async () => (await mirrorEntry('crew2'))?.firstName === 'Renamed',
    { label: 'profile edit propagated' }
  );
});

test('fcm tokens are written to /users but never leak into the mirror', async () => {
  const record = {
    id: 'crew3', email: 'crew3@example.org', firstName: 'Crew', lastName: 'Three',
    role: 'driver', municipalityId: 'muniA', isActive: true,
    isVerified: false, createdAt: T0,
  };
  await registerAndApprove('crew3', record);
  await waitFor(async () => (await mirrorEntry('crew3'))?.isApproved === true, {
    label: 'mirror entry for crew3 (approved)',
  });

  await dbAs('crew3').ref('users/crew3/fcmToken').set('secret-push-token');
  await dbAs('crew3').ref('users/crew3/lastLoginAt').set(T1);

  // lastLoginAt proves the mirror was re-written after the token save
  await waitFor(
    async () => (await mirrorEntry('crew3'))?.lastLoginAt === T1,
    { label: 'token-save rewrite propagated' }
  );
  const entry = await mirrorEntry('crew3');
  assert.equal(entry.fcmToken, undefined, 'fcmToken must not leak to municipal admins');
  // sanity: the token did land in /users
  const raw = await adminRead('users/crew3/fcmToken');
  assert.equal(raw.val(), 'secret-push-token');
});

test('citizens without a municipality get no mirror entry', async () => {
  const record = {
    id: 'cit9', email: 'cit9@example.org', firstName: 'C', lastName: 'T',
    role: 'citizen', isApproved: true, isActive: true, isVerified: false, createdAt: T0,
  };
  await dbAs('cit9').ref('users/cit9').set(record);
  await dbAs('cit9').ref('users/cit9/firstName').set('Renamed');

  // wait until /users write was processed, then ensure no mirror appeared
  await waitFor(
    async () => (await adminRead('users/cit9/firstName')).val() === 'Renamed',
    { label: '/users write processed' }
  );
  assert.equal(await mirrorEntry('cit9'), null);
});

test('deleting a user removes the mirror entry', async () => {
  const record = {
    id: 'crew4', email: 'crew4@example.org', firstName: 'Crew', lastName: 'Four',
    role: 'driver', municipalityId: 'muniA', isActive: true,
    isVerified: false, createdAt: T0,
  };
  await registerAndApprove('crew4', record);
  await waitFor(() => mirrorEntry('crew4'), { label: 'mirror entry for crew4' });

  await dbAs('crew4').ref('users/crew4').remove();
  await waitFor(async () => (await mirrorEntry('crew4')) === null, {
    label: 'mirror entry removal',
  });
});

test('municipality change moves the mirror entry', async () => {
  await testEnv.withSecurityRulesDisabled((ctx) =>
    ctx.database().ref('municipalities/muniB').set({
      id: 'muniB', name: 'Beta', province: 'B', region: 'R', createdAt: T0,
    })
  );
  const record = {
    id: 'crew5', email: 'crew5@example.org', firstName: 'Crew', lastName: 'Five',
    role: 'driver', municipalityId: 'muniA', isActive: true,
    isVerified: false, createdAt: T0,
  };
  await registerAndApprove('crew5', record);
  await waitFor(() => mirrorEntry('crew5'), { label: 'mirror entry for crew5' });

  // municipality reassignment is a super-admin action (done here bypassing rules
  // to simulate the privileged write)
  await testEnv.withSecurityRulesDisabled((ctx) =>
    ctx.database().ref('users/crew5/municipalityId').set('muniB')
  );

  await waitFor(async () => {
    const entry = await mirrorEntry('crew5');
    return entry && entry.municipalityId === 'muniB';
  }, { label: 'mirror move to muniB' });

  const buckets = await adminRead('municipality_users');
  const all = buckets.val() || {};
  assert.equal(all.muniA && all.muniA.crew5, undefined, 'old entry removed');
  assert.ok(all.muniB && all.muniB.crew5, 'new entry created');
});
