/**
 * ADMS Firebase Realtime Database security rules — authorization matrix.
 *
 * Run from the repository root:
 *   firebase emulators:exec --only database,functions --project demo-adms \
 *     "node --test --test-concurrency=1 tests/database-rules/rules.test.mjs tests/database-rules/mirror-sync.test.mjs"
 *
 * --test-concurrency=1 is required when combining test files: node runs test
 * files in parallel by default and both files clear the same emulator database
 * in beforeEach, which makes them wipe each other's fixtures.
 *
 * The matrix mirrors the real application flows (registration, sign-in,
 * dispatch lifecycle, ePCR, staff directory, admin operations) and the
 * security properties the audit requires:
 *   - unapproved/deactivated accounts have no access beyond their own record
 *   - super admin / municipal admin / driver / citizen boundaries
 *   - municipality scoping everywhere (no cross-municipality access)
 *   - citizens can only create their own incidents and only read them back
 *   - drivers can only touch the incident/unit they are assigned to
 *   - linear incident lifecycle is enforced authoritatively
 *   - /users is never queryable below super admin (municipal directory is
 *     served by the CF-written /municipality_users mirror, client-read-only)
 */

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const RULES_URL = new URL('../../source/flutter/adms/database.rules.json', import.meta.url);

let testEnv;

const T0 = '2026-01-01T00:00:00.000';
const T1 = '2026-01-01T00:05:00.000';

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

/** Database reference for a user id, or for an unauthenticated client. */
function dbAs(uid) {
  if (uid === null || uid === undefined) {
    return testEnv.unauthenticatedContext().database();
  }
  return testEnv.authenticatedContext(uid).database();
}

function userRecord(id, overrides = {}) {
  return {
    id,
    email: `${id}@example.org`,
    firstName: 'First',
    lastName: 'Last',
    phoneNumber: '+63000000000',
    role: 'citizen',
    isVerified: false,
    isActive: true,
    isApproved: true,
    createdAt: T0,
    ...overrides,
  };
}

function incidentRecord(id, municipalityId, status, overrides = {}) {
  return {
    id,
    municipalityId,
    latitude: 14.5995,
    longitude: 120.9842,
    severity: 'high',
    status,
    address: '123 Test St',
    reporterName: 'Reporter',
    reporterPhone: '+63000000000',
    createdAt: T0,
    ...overrides,
  };
}

async function seed(ctx) {
  await ctx.database().ref().update({
    // municipalities -------------------------------------------------------
    'municipalities/muniA': {
      id: 'muniA', name: 'Alpha City', province: 'Alpha', region: 'Region I',
      createdAt: T0, isActive: true,
    },
    'municipalities/muniB': {
      id: 'muniB', name: 'Beta Town', province: 'Beta', region: 'Region II',
      createdAt: T0, isActive: true,
    },

    // users ----------------------------------------------------------------
    'users/super1': userRecord('super1', {
      role: 'superAdmin', isVerified: true,
    }),
    'users/adminA': userRecord('adminA', {
      role: 'municipalAdmin', municipalityId: 'muniA', municipalityName: 'Alpha City',
    }),
    'users/adminB': userRecord('adminB', {
      role: 'municipalAdmin', municipalityId: 'muniB', municipalityName: 'Beta Town',
    }),
    'users/driver1': userRecord('driver1', {
      role: 'driver', municipalityId: 'muniA', municipalityName: 'Alpha City',
    }),
    'users/driver2': userRecord('driver2', {
      role: 'driver', municipalityId: 'muniB', municipalityName: 'Beta Town',
    }),
    'users/pending1': userRecord('pending1', {
      role: 'driver', municipalityId: 'muniA', isApproved: false,
    }),
    'users/deactA': userRecord('deactA', {
      role: 'municipalAdmin', municipalityId: 'muniA', isActive: false,
    }),
    'users/citizen1': userRecord('citizen1'),
    'users/citizen2': userRecord('citizen2'),

    // municipality directory mirror (normally written by the CF) -----------
    'municipality_users/muniA/adminA': userRecord('adminA', {
      role: 'municipalAdmin', municipalityId: 'muniA',
    }),
    'municipality_users/muniA/driver1': userRecord('driver1', {
      role: 'driver', municipalityId: 'muniA',
    }),
    'municipality_users/muniA/pending1': userRecord('pending1', {
      role: 'driver', municipalityId: 'muniA', isApproved: false,
    }),
    'municipality_users/muniB/adminB': userRecord('adminB', {
      role: 'municipalAdmin', municipalityId: 'muniB',
    }),

    // units ----------------------------------------------------------------
    'units/muniA/unit1': {
      id: 'unit1', municipalityId: 'muniA', callSign: 'ALPHA-1',
      type: 'basic', status: 'available', assignedDriverId: 'driver1',
      assignedDriverName: 'Driver One', latitude: 14.6, longitude: 121.0,
      isActive: true, createdAt: T0,
    },
    'units/muniB/unit2': {
      id: 'unit2', municipalityId: 'muniB', callSign: 'BETA-1',
      type: 'basic', status: 'available', assignedDriverId: 'driver2',
      assignedDriverName: 'Driver Two', latitude: 14.7, longitude: 121.1,
      isActive: true, createdAt: T0,
    },

    // incidents ------------------------------------------------------------
    'incidents/muniA/inc1': incidentRecord('inc1', 'muniA', 'pending', {
      reporterId: 'citizen1', reporterName: 'Citizen One',
    }),
    'incidents/muniA/inc2': incidentRecord('inc2', 'muniA', 'dispatched', {
      reporterId: 'citizen2', assignedDriverId: 'driver1',
      assignedDriverName: 'Driver One', assignedUnitId: 'unit1',
    }),
    'incidents/muniA/inc3': incidentRecord('inc3', 'muniA', 'atHospital', {
      reporterId: 'citizen1', assignedDriverId: 'driver1',
      assignedDriverName: 'Driver One', assignedUnitId: 'unit1',
    }),
    'incidents/muniA/inc4': incidentRecord('inc4', 'muniA', 'acknowledged', {
      dispatcherId: 'adminA',
    }),
    'incidents/muniA/inc5': incidentRecord('inc5', 'muniA', 'resolved', {
      assignedDriverId: 'driver1',
    }),
    'incidents/muniB/inc6': incidentRecord('inc6', 'muniB', 'pending', {
      reporterId: 'citizen2',
    }),

    // indexes --------------------------------------------------------------
    'user_incidents/citizen1': { inc1: true, inc3: true },
    'user_incidents/citizen2': { inc2: true, inc6: true },
    'incident_index/inc1': 'muniA',
    'incident_index/inc2': 'muniA',
    'incident_index/inc3': 'muniA',
    'incident_index/inc4': 'muniA',
    'incident_index/inc5': 'muniA',
    'incident_index/inc6': 'muniB',
    'driver_units/driver1': 'muniA/unit1',
    'driver_units/driver2': 'muniB/unit2',

    // patient reports (ePCR) ----------------------------------------------
    'patient_reports/muniA/epcr1': {
      id: 'epcr1', municipalityId: 'muniA', incidentId: 'inc2',
      patientFirstName: 'Pat', patientLastName: 'Ient', driverId: 'driver1',
      status: 'submitted', createdAt: T0,
    },

    // maintenance ----------------------------------------------------------
    'maintenance/muniA/maint1': {
      id: 'maint1', municipalityId: 'muniA', unitId: 'unit1',
      description: 'Tyre change', createdAt: T0,
    },

    // invites / audit / config --------------------------------------------
    'invites/tok1': {
      email: 'crew@example.org', role: 'driver', municipalityId: 'muniA',
      createdAt: T0, used: false,
    },
    'auditLog/aud1': { type: 'role_change', uid: 'driver1', timestamp: 1 },
    systemConfig: { autoDispatchEnabled: false, sessionTimeoutMinutes: 15 },
  });
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

// ===========================================================================
// USERS
// ===========================================================================

test('users: super admin reads the full /users collection', async () => {
  await assertSucceeds(dbAs('super1').ref('users').get());
});

test('users: municipal admin CANNOT query /users (query rules are not row filters)', async () => {
  await assertFails(
    dbAs('adminA').ref('users').orderByChild('municipalityId').equalTo('muniA').get()
  );
});

test('users: citizen cannot read /users root or another user', async () => {
  await assertFails(dbAs('citizen1').ref('users').get());
  await assertFails(dbAs('citizen1').ref('users/driver1').get());
});

test('users: users read their own profile, even when unapproved', async () => {
  await assertSucceeds(dbAs('citizen1').ref('users/citizen1').get());
  await assertSucceeds(dbAs('pending1').ref('users/pending1').get());
  await assertSucceeds(dbAs('deactA').ref('users/deactA').get());
});

test('users: unauthenticated read denied', async () => {
  await assertFails(dbAs(null).ref('users/super1').get());
});

test('users: self-registration as citizen succeeds', async () => {
  await assertSucceeds(
    dbAs('fresh1').ref('users/fresh1').set(
      userRecord('fresh1', { role: 'citizen', isApproved: true })
    )
  );
});

test('users: self-registration as driver (unapproved, real municipality) succeeds', async () => {
  await assertSucceeds(
    dbAs('fresh2').ref('users/fresh2').set(
      userRecord('fresh2', { role: 'driver', isApproved: false, municipalityId: 'muniA' })
    )
  );
});

test('users: self-registration as municipalAdmin only possible unapproved', async () => {
  await assertSucceeds(
    dbAs('fresh3').ref('users/fresh3').set(
      userRecord('fresh3', { role: 'municipalAdmin', isApproved: false, municipalityId: 'muniA' })
    )
  );
  await assertFails(
    dbAs('fresh4').ref('users/fresh4').set(
      userRecord('fresh4', { role: 'municipalAdmin', isApproved: true, municipalityId: 'muniA' })
    )
  );
});

test('users: privilege escalation via self-registration is blocked', async () => {
  // superAdmin role is never self-registrable
  await assertFails(
    dbAs('evil1').ref('users/evil1').set(userRecord('evil1', { role: 'superAdmin' }))
  );
  await assertFails(
    dbAs('evil2').ref('users/evil2').set(
      userRecord('evil2', { role: 'superAdmin', isApproved: false })
    )
  );
  // driver cannot self-register as already approved
  await assertFails(
    dbAs('evil3').ref('users/evil3').set(
      userRecord('evil3', { role: 'driver', isApproved: true, municipalityId: 'muniA' })
    )
  );
  // inactive-on-create is rejected
  await assertFails(
    dbAs('evil4').ref('users/evil4').set(
      userRecord('evil4', { role: 'citizen', isActive: false })
    )
  );
  // municipality must exist
  await assertFails(
    dbAs('evil5').ref('users/evil5').set(
      userRecord('evil5', { role: 'driver', isApproved: false, municipalityId: 'nope' })
    )
  );
  // registration without required fields is rejected
  await assertFails(dbAs('evil6').ref('users/evil6').set({ email: 'x@y.z' }));
});

test('users: pending driver can update own sign-in timestamp but not privilege fields', async () => {
  // lastLoginAt is written by the sign-in flow
  await assertSucceeds(dbAs('pending1').ref('users/pending1/lastLoginAt').set(T1));
  // but an unapproved driver can never approve or promote itself
  await assertFails(dbAs('pending1').ref('users/pending1/isApproved').set(true));
  await assertFails(dbAs('pending1').ref('users/pending1/role').set('superAdmin'));
  await assertFails(dbAs('pending1').ref('users/pending1/role').set('municipalAdmin'));
  await assertFails(dbAs('pending1').ref('users/pending1/municipalityId').set('muniB'));
});

test('users: citizen cannot change own role/municipality or approve themselves', async () => {
  await assertFails(dbAs('citizen1').ref('users/citizen1/role').set('superAdmin'));
  await assertFails(dbAs('citizen1').ref('users/citizen1/municipalityId').set('muniA'));
  // full-record overwrite keeping privilege fields unchanged is allowed
  // (profile edit), but flipping a privilege field is not
  await assertFails(
    dbAs('citizen1').ref('users/citizen1').set(
      userRecord('citizen1', { role: 'driver', isApproved: false, municipalityId: 'muniA' })
    )
  );
});

test('users: citizen profile update (name/phone/fcm token) succeeds', async () => {
  await assertSucceeds(dbAs('citizen1').ref('users/citizen1/firstName').set('Renamed'));
  await assertSucceeds(dbAs('citizen1').ref('users/citizen1/phoneNumber').set('+63111'));
  await assertSucceeds(dbAs('citizen1').ref('users/citizen1/fcmToken').set('tok'));
});

test('users: citizen cannot edit own email address', async () => {
  await assertFails(dbAs('citizen1').ref('users/citizen1/email').set('new@example.org'));
});

test('users: municipal admin approves/deactivates users of own municipality only', async () => {
  await assertSucceeds(dbAs('adminA').ref('users/pending1/isApproved').set(true));
  await assertSucceeds(dbAs('adminA').ref('users/driver1/isActive').set(false));
  // other municipality: read and write are both out of reach
  await assertFails(dbAs('adminA').ref('users/driver2').get());
  await assertFails(dbAs('adminA').ref('users/driver2/isActive').set(false));
  await assertFails(dbAs('adminA').ref('users/driver2/isApproved').set(false));
  // users without a municipality are not fair game either
  await assertFails(dbAs('adminA').ref('users/citizen1/isActive').set(false));
});

test('users: only super admin can change roles or municipalities', async () => {
  await assertSucceeds(dbAs('super1').ref('users/driver1/role').set('municipalAdmin'));
  await assertSucceeds(dbAs('super1').ref('users/driver1/municipalityId').set('muniB'));
  await assertFails(dbAs('adminA').ref('users/pending1/role').set('municipalAdmin'));
  await assertFails(dbAs('adminA').ref('users/pending1/municipalityId').set('muniB'));
});

test('users: municipal admin cannot delete users; self-deletion is allowed', async () => {
  await assertFails(dbAs('adminA').ref('users/driver1').remove());
  await assertSucceeds(dbAs('citizen1').ref('users/citizen1').remove());
});

test('users: deactivated accounts lose all data access (but keep own profile)', async () => {
  await assertFails(dbAs('deactA').ref('incidents/muniA').get());
  await assertFails(dbAs('deactA').ref('units/muniA').get());
  await assertFails(dbAs('deactA').ref('patient_reports/muniA').get());
  await assertFails(dbAs('deactA').ref('users/pending1/isApproved').set(true));
  await assertSucceeds(dbAs('deactA').ref('users/deactA/firstName').set('Still Me'));
});

test('users: unapproved accounts lose all data access', async () => {
  await assertFails(dbAs('pending1').ref('incidents/muniA').get());
  await assertFails(dbAs('pending1').ref('units/muniA').get());
  await assertFails(dbAs('pending1').ref('patient_reports/muniA').get());
  await assertFails(dbAs('pending1').ref('municipality_users/muniA').get());
  await assertFails(dbAs('pending1').ref('incident_index/inc1').get());
  await assertSucceeds(dbAs('pending1').ref('systemConfig').get());
  await assertSucceeds(dbAs('pending1').ref('users/pending1').get());
});

test('users: accounts without a profile record have no access', async () => {
  await assertFails(dbAs('ghost').ref('incidents/muniA').get());
  await assertFails(dbAs('ghost').ref('units/muniA').get());
});

// ===========================================================================
// MUNICIPALITY USERS MIRROR
// ===========================================================================

test('mirror: municipal admin reads own-municipality directory only', async () => {
  await assertSucceeds(dbAs('adminA').ref('municipality_users/muniA').get());
  await assertFails(dbAs('adminA').ref('municipality_users/muniB').get());
  await assertSucceeds(dbAs('super1').ref('municipality_users/muniA').get());
});

test('mirror: drivers/citizens/unauthenticated cannot read the directory', async () => {
  await assertFails(dbAs('driver1').ref('municipality_users/muniA').get());
  await assertFails(dbAs('citizen1').ref('municipality_users/muniA').get());
  await assertFails(dbAs(null).ref('municipality_users/muniA').get());
  await assertFails(dbAs('pending1').ref('municipality_users/muniA').get());
});

test('mirror: no client — not even the super admin — can write it', async () => {
  await assertFails(
    dbAs('super1').ref('municipality_users/muniA/hacker').set(userRecord('hacker'))
  );
  await assertFails(
    dbAs('adminA').ref('municipality_users/muniA/adminA/role').set('superAdmin')
  );
  await assertFails(
    dbAs('citizen1').ref('municipality_users/muniA/citizen1').set(userRecord('citizen1'))
  );
});

// ===========================================================================
// MUNICIPALITIES
// ===========================================================================

test('municipalities: public directory read (registration form), no public writes', async () => {
  await assertSucceeds(dbAs(null).ref('municipalities').get());
  await assertFails(
    dbAs(null).ref('municipalities/muniA').set({ id: 'muniA', name: 'Pwned', createdAt: T0 })
  );
});

test('municipalities: super admin manages, admin updates own only', async () => {
  await assertSucceeds(
    dbAs('super1').ref('municipalities/muniC').set({
      id: 'muniC', name: 'Gamma', province: 'P', region: 'R', createdAt: T0,
    })
  );
  await assertSucceeds(dbAs('adminA').ref('municipalities/muniA/name').set('Alpha City 2'));
  await assertFails(dbAs('adminA').ref('municipalities/muniB/name').set('Beta 2'));
  await assertFails(
    dbAs('adminA').ref('municipalities/muniC').set({
      id: 'muniC', name: 'New', province: 'P', region: 'R', createdAt: T0,
    })
  );
  await assertFails(dbAs('adminA').ref('municipalities/muniA').remove());
  await assertFails(dbAs('driver1').ref('municipalities/muniA/name').set('Nope'));
});

// ===========================================================================
// INCIDENTS — READS
// ===========================================================================

test('incidents: municipality-scoped reads', async () => {
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA').get());
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA').get());
  await assertSucceeds(dbAs('super1').ref('incidents/muniA').get());
  await assertSucceeds(dbAs('super1').ref('incidents').get()); // system-wide analytics
  await assertFails(dbAs('adminB').ref('incidents/muniA').get());
  await assertFails(dbAs('driver2').ref('incidents/muniA').get());
  await assertFails(dbAs('citizen1').ref('incidents/muniA').get());
  await assertFails(dbAs(null).ref('incidents/muniA').get());
  await assertFails(dbAs('pending1').ref('incidents/muniA').get());
});

test('incidents: indexed query within a municipality still requires bucket read access', async () => {
  await assertSucceeds(
    dbAs('adminA').ref('incidents/muniA').orderByChild('status').equalTo('pending').get()
  );
  await assertFails(
    dbAs('citizen1').ref('incidents/muniA').orderByChild('status').equalTo('pending').get()
  );
});

test('incidents: citizens read back only the incidents they reported', async () => {
  await assertSucceeds(dbAs('citizen1').ref('incidents/muniA/inc1').get());
  await assertFails(dbAs('citizen1').ref('incidents/muniA/inc2').get());
  await assertFails(dbAs('citizen2').ref('incidents/muniA/inc1').get());
  await assertFails(dbAs('citizen1').ref('incidents/muniB/inc6').get());
});

// ===========================================================================
// INCIDENTS — WRITES + LIFECYCLE
// ===========================================================================

test('incidents: citizen reports an incident (full app multi-path write)', async () => {
  const incident = incidentRecord('inc9', 'muniA', 'pending', {
    reporterId: 'citizen1', reporterName: 'Citizen One',
  });
  await assertSucceeds(
    dbAs('citizen1').ref().update({
      'incidents/muniA/inc9': incident,
      'user_incidents/citizen1/inc9': true,
      'incident_index/inc9': 'muniA',
    })
  );
});

test('incidents: citizen cannot forge reporter, status, or municipality on create', async () => {
  await assertFails(
    dbAs('citizen1').ref('incidents/muniA/inc10').set(
      incidentRecord('inc10', 'muniA', 'pending', { reporterId: 'citizen2' })
    )
  );
  await assertFails(
    dbAs('citizen1').ref('incidents/muniA/inc11').set(
      incidentRecord('inc11', 'muniA', 'acknowledged', { reporterId: 'citizen1' })
    )
  );
  // ...but reporting INTO another municipality is legitimate: citizens have
  // no municipality membership — they report by the incident's location.
  await assertSucceeds(
    dbAs('citizen1').ref('incidents/muniB/inc12').set(
      incidentRecord('inc12', 'muniB', 'pending', { reporterId: 'citizen1' })
    )
  );
  // create missing required fields
  await assertFails(
    dbAs('citizen1').ref('incidents/muniA/inc13').set({ id: 'inc13', status: 'pending' })
  );
  // key/record mismatch
  await assertFails(
    dbAs('citizen1').ref('incidents/muniA/inc14').set(
      incidentRecord('otherId', 'muniA', 'pending', { reporterId: 'citizen1' })
    )
  );
});

test('incidents: citizens cannot update or delete existing incidents', async () => {
  await assertFails(dbAs('citizen1').ref('incidents/muniA/inc1/description').set('edited'));
  await assertFails(dbAs('citizen1').ref('incidents/muniA/inc1').remove());
});

test('incidents: unauthenticated and unapproved clients cannot create incidents', async () => {
  await assertFails(
    dbAs(null).ref('incidents/muniA/incX').set(
      incidentRecord('incX', 'muniA', 'pending', { reporterId: 'citizen1' })
    )
  );
  await assertFails(
    dbAs('pending1').ref('incidents/muniA/incY').set(
      incidentRecord('incY', 'muniA', 'pending', { reporterId: 'pending1' })
    )
  );
});

test('lifecycle: municipal admin acknowledges and dispatches', async () => {
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc1/status').set('acknowledged'));
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc4/status').set('dispatched'));
});

test('lifecycle: admin dispatch is atomic across incidents + units', async () => {
  await assertSucceeds(
    dbAs('adminA').ref().update({
      'incidents/muniA/inc4/status': 'dispatched',
      'incidents/muniA/inc4/assignedDriverId': 'driver1',
      'incidents/muniA/inc4/assignedDriverName': 'Driver One',
      'incidents/muniA/inc4/assignedUnitId': 'unit1',
      'incidents/muniA/inc4/dispatchedAt': T1,
      'units/muniA/unit1/status': 'enRoute',
      'units/muniA/unit1/currentIncidentId': 'inc4',
      'units/muniA/unit1/lastStatusChangeAt': T1,
    })
  );
});

test('lifecycle: assigned driver drives the full forward chain, no skips', async () => {
  // inc2 starts at dispatched and assigned to driver1
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA/inc2/status').set('enRoute'));
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA/inc2/status').set('onScene'));
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA/inc2/status').set('transporting'));
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA/inc2/status').set('atHospital'));
  await assertSucceeds(dbAs('driver1').ref('incidents/muniA/inc2/status').set('resolved'));
  // ...but skipping a stage is rejected
  await assertFails(dbAs('driver1').ref('incidents/muniA/inc2/status').set('onScene'));
});

test('lifecycle: backwards transitions and reopening are rejected', async () => {
  // inc3 is atHospital
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc3/status').set('dispatched'));
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc3/status').set('onScene'));
  // inc5 is resolved — terminal for every role below super admin
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc5/status').set('cancelled'));
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc5/status').set('atHospital'));
  await assertFails(dbAs('driver1').ref('incidents/muniA/inc5/status').set('transporting'));
  // resolved incidents still allow non-status field updates (notes etc.)
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc5/dispatchNotes').set('ok'));
});

test('lifecycle: resolution from atHospital succeeds, super admin may override', async () => {
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc3/status').set('resolved'));
  // super admin can jump states (support / data repair)
  await assertSucceeds(dbAs('super1').ref('incidents/muniA/inc1/status').set('resolved'));
});

test('lifecycle: cancellation from active states succeeds, from pending too', async () => {
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc4/status').set('cancelled'));
  await assertSucceeds(dbAs('adminA').ref('incidents/muniA/inc1/status').set('cancelled'));
});

test('lifecycle: a driver cannot act on unassigned incidents', async () => {
  await assertFails(dbAs('driver1').ref('incidents/muniA/inc1/status').set('enRoute'));
  await assertFails(dbAs('driver1').ref('incidents/muniA/inc4/status').set('enRoute'));
  // and cannot reassign an incident to themselves
  await assertFails(
    dbAs('driver1').ref('incidents/muniA/inc1/assignedDriverId').set('driver1')
  );
  // driver from another municipality cannot touch this incident at all
  await assertFails(dbAs('driver2').ref('incidents/muniA/inc2/status').set('onScene'));
});

test('lifecycle: driver transition is atomic across incident + own unit', async () => {
  await assertSucceeds(
    dbAs('driver1').ref().update({
      'incidents/muniA/inc2/status': 'enRoute',
      'incidents/muniA/inc2/enRouteAt': T1,
      'units/muniA/unit1/status': 'enRoute',
      'units/muniA/unit1/lastStatusChangeAt': T1,
    })
  );
  // driver2's unit belongs to another municipality — rejected even as part of
  // a multi-path update
  await assertFails(
    dbAs('driver1').ref().update({
      'incidents/muniA/inc2/status': 'enRoute',
      'units/muniB/unit2/status': 'onScene',
    })
  );
});

test('incidents: only super admin can delete; identity fields are immutable', async () => {
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc1').remove());
  await assertSucceeds(dbAs('super1').ref('incidents/muniA/inc1').remove());
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc2/createdAt').set(T1));
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc2/id').set('incHacked'));
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc2/municipalityId').set('muniB'));
  await assertFails(dbAs('adminA').ref('incidents/muniA/inc2/reporterId').set('adminA'));
});

test('incidents: cross-municipality writes are rejected', async () => {
  await assertFails(dbAs('adminB').ref('incidents/muniA/inc1/status').set('acknowledged'));
  await assertFails(
    dbAs('driver2').ref('incidents/muniB/inc6/status').set('acknowledged')
  ); // driver2 not assigned to inc6
});

// ===========================================================================
// USER / INCIDENT INDEXES
// ===========================================================================

test('indexes: user_incidents is readable/writable only by its owner', async () => {
  await assertSucceeds(dbAs('citizen1').ref('user_incidents/citizen1/inc9').set(true));
  await assertFails(dbAs('citizen1').ref('user_incidents/citizen1/inc9').set(false));
  await assertSucceeds(dbAs('citizen1').ref('user_incidents/citizen1').get());
  await assertFails(dbAs('citizen2').ref('user_incidents/citizen1').get());
  await assertFails(dbAs('citizen2').ref('user_incidents/citizen1/inc9').set(true));
  await assertSucceeds(dbAs('super1').ref('user_incidents/citizen1').get());
});

test('indexes: incident_index allows creating valid mappings only, never rewriting', async () => {
  await assertSucceeds(dbAs('adminA').ref('incident_index/incNew').set('muniA'));
  await assertFails(dbAs('citizen1').ref('incident_index/incNew2').set('not-a-muni'));
  await assertFails(dbAs('citizen1').ref('incident_index/inc1').set('muniB'));
  await assertFails(dbAs('citizen1').ref('incident_index/inc1').remove());
  await assertSucceeds(dbAs('citizen1').ref('incident_index').get());
  await assertFails(dbAs(null).ref('incident_index').get());
  await assertFails(dbAs('pending1').ref('incident_index').get());
});

test('indexes: driver_units is admin-maintained, driver-readable', async () => {
  await assertSucceeds(dbAs('adminA').ref('driver_units/driver9').set('muniA/unit1'));
  await assertFails(dbAs('driver1').ref('driver_units/driver9').set('muniA/unit1'));
  await assertFails(dbAs('driver1').ref('driver_units/driver2').set('muniA/unit1'));
  await assertSucceeds(dbAs('driver1').ref('driver_units/driver1').get());
  await assertFails(dbAs('driver1').ref('driver_units/driver2').get());
  await assertSucceeds(dbAs('super1').ref('driver_units/driver1').get());
  await assertFails(dbAs('adminA').ref('driver_units/driver1').get()); // admin directory comes from the mirror, not this index
});

// ===========================================================================
// UNITS
// ===========================================================================

test('units: municipality-scoped reads', async () => {
  await assertSucceeds(dbAs('adminA').ref('units/muniA').get());
  await assertSucceeds(dbAs('driver1').ref('units/muniA').get());
  await assertSucceeds(dbAs('super1').ref('units').get());
  await assertFails(dbAs('adminB').ref('units/muniA').get());
  await assertFails(dbAs('driver2').ref('units/muniA').get());
  await assertFails(dbAs('citizen1').ref('units/muniA').get());
  await assertFails(dbAs(null).ref('units/muniA').get());
  await assertFails(dbAs('pending1').ref('units/muniA').get());
});

test('units: admin creates/updates/deletes within own municipality only', async () => {
  await assertSucceeds(
    dbAs('adminA').ref('units/muniA/unit9').set({
      id: 'unit9', municipalityId: 'muniA', callSign: 'ALPHA-9', status: 'available',
      createdAt: T0,
    })
  );
  await assertFails(
    dbAs('adminA').ref('units/muniA/unit9').set({
      id: 'unit9', municipalityId: 'muniB', callSign: 'X', status: 'available', createdAt: T0,
    })
  );
  await assertFails(
    dbAs('adminA').ref('units/muniB/unit8').set({
      id: 'unit8', municipalityId: 'muniB', callSign: 'B-8', status: 'available', createdAt: T0,
    })
  );
  await assertSucceeds(dbAs('adminA').ref('units/muniA/unit9').remove());
  await assertFails(dbAs('driver1').ref('units/muniA/unit1').remove());
});

test('units: assigned driver updates own unit status/location only', async () => {
  await assertSucceeds(dbAs('driver1').ref('units/muniA/unit1/status').set('enRoute'));
  await assertSucceeds(dbAs('driver1').ref('units/muniA/unit1/latitude').set(14.61));
  await assertSucceeds(dbAs('driver1').ref('units/muniA/unit1/locationUpdatedAt').set(T1));
  // administrative fields are off-limits for drivers
  await assertFails(dbAs('driver1').ref('units/muniA/unit1/callSign').set('HACK'));
  await assertFails(dbAs('driver1').ref('units/muniA/unit1/assignedDriverId').set('driver2'));
  await assertFails(dbAs('driver1').ref('units/muniA/unit1/assignedDriverName').set('X'));
  await assertFails(dbAs('driver1').ref('units/muniA/unit1/municipalityId').set('muniB'));
  // unassigned driver of the same municipality cannot touch it
  await assertFails(dbAs('pending1').ref('units/muniA/unit1/status').set('outOfService'));
  // driver of another municipality cannot touch it
  await assertFails(dbAs('driver2').ref('units/muniA/unit1/status').set('onScene'));
});

test('units: driver cannot create units', async () => {
  await assertFails(
    dbAs('driver1').ref('units/muniA/unit10').set({
      id: 'unit10', municipalityId: 'muniA', callSign: 'A-10', status: 'available', createdAt: T0,
    })
  );
});

// ===========================================================================
// PATIENT REPORTS (ePCR)
// ===========================================================================

test('patient_reports: strict municipality + role scoping for reads', async () => {
  await assertSucceeds(dbAs('driver1').ref('patient_reports/muniA').get());
  await assertSucceeds(dbAs('adminA').ref('patient_reports/muniA').get());
  await assertSucceeds(dbAs('super1').ref('patient_reports').get());
  await assertFails(dbAs('driver2').ref('patient_reports/muniA').get());
  await assertFails(dbAs('adminB').ref('patient_reports/muniA').get());
  await assertFails(dbAs('citizen1').ref('patient_reports/muniA').get());
  await assertFails(dbAs('pending1').ref('patient_reports/muniA').get());
  await assertFails(dbAs(null).ref('patient_reports/muniA').get());
});

test('patient_reports: drivers create/update but never delete; admins manage', async () => {
  await assertSucceeds(
    dbAs('driver1').ref('patient_reports/muniA/epcr2').set({
      id: 'epcr2', municipalityId: 'muniA', incidentId: 'inc2', driverId: 'driver1',
      createdAt: T0,
    })
  );
  await assertFails(
    dbAs('driver1').ref('patient_reports/muniA/epcr1').remove()
  );
  await assertFails(
    dbAs('driver2').ref('patient_reports/muniA/epcr3').set({
      id: 'epcr3', municipalityId: 'muniA', driverId: 'driver2', createdAt: T0,
    })
  );
  await assertSucceeds(dbAs('adminA').ref('patient_reports/muniA/epcr1/status').set('reviewed'));
  await assertSucceeds(dbAs('adminA').ref('patient_reports/muniA/epcr1').remove());
  await assertFails(dbAs('adminB').ref('patient_reports/muniA/epcr1').remove());
  await assertFails(dbAs('pending1').ref('patient_reports/muniA/epcr4').set({ id: 'epcr4' }));
});

// ===========================================================================
// MAINTENANCE
// ===========================================================================

test('maintenance: admin CRUD in own municipality, nothing for others', async () => {
  await assertSucceeds(
    dbAs('adminA').ref('maintenance/muniA/maint2').set({
      id: 'maint2', municipalityId: 'muniA', description: 'Oil', createdAt: T0,
    })
  );
  await assertSucceeds(dbAs('adminA').ref('maintenance/muniA/maint1').remove());
  await assertFails(
    dbAs('adminA').ref('maintenance/muniB/maint3').set({
      id: 'maint3', municipalityId: 'muniB', description: 'X', createdAt: T0,
    })
  );
  await assertFails(dbAs('adminA').ref('maintenance/muniB').get());
  await assertFails(dbAs('driver1').ref('maintenance/muniA').get());
  await assertFails(dbAs('driver1').ref('maintenance/muniA/maint9').set({ id: 'maint9' }));
  await assertSucceeds(dbAs('super1').ref('maintenance/muniB/maint4').set({
    id: 'maint4', municipalityId: 'muniB', description: 'S', createdAt: T0,
  }));
});

// ===========================================================================
// AUDIT LOG
// ===========================================================================

test('auditLog: admins read, nobody writes from a client', async () => {
  await assertSucceeds(dbAs('super1').ref('auditLog').get());
  await assertSucceeds(dbAs('adminA').ref('auditLog').orderByChild('timestamp').get());
  await assertFails(dbAs('driver1').ref('auditLog').get());
  await assertFails(dbAs('citizen1').ref('auditLog').get());
  await assertFails(dbAs(null).ref('auditLog').get());
  await assertFails(
    dbAs('adminA').ref('auditLog/aud2').set({
      id: 'aud2', action: 'tamper', performedByUid: 'adminA', timestamp: T0,
    })
  );
  await assertFails(dbAs('super1').ref('auditLog/aud1').remove());
});

// ===========================================================================
// SYSTEM CONFIG
// ===========================================================================

test('systemConfig: authenticated read, super admin write', async () => {
  await assertSucceeds(dbAs('citizen1').ref('systemConfig').get());
  await assertSucceeds(dbAs('driver1').ref('systemConfig').get());
  await assertFails(dbAs(null).ref('systemConfig').get());
  await assertSucceeds(
    dbAs('super1').ref('systemConfig/autoDispatchEnabled').set(true)
  );
  await assertFails(dbAs('adminA').ref('systemConfig/autoDispatchEnabled').set(true));
  await assertFails(dbAs('driver1').ref('systemConfig/sessionTimeoutMinutes').set(1));
  await assertFails(dbAs('pending1').ref('systemConfig/autoDispatchEnabled').set(true));
});

// ===========================================================================
// INVITES
// ===========================================================================

test('invites: admins read; own-municipality admin creates; nobody else', async () => {
  await assertSucceeds(dbAs('adminA').ref('invites').get());
  await assertFails(dbAs('driver1').ref('invites').get());
  await assertFails(dbAs(null).ref('invites').get());
  await assertSucceeds(
    dbAs('adminA').ref('invites/tok2').set({
      email: 'x@example.org', role: 'driver', municipalityId: 'muniA',
      createdAt: T0, used: false,
    })
  );
  await assertFails(
    dbAs('adminA').ref('invites/tok3').set({
      email: 'y@example.org', role: 'driver', municipalityId: 'muniB',
      createdAt: T0, used: false,
    })
  );
  await assertFails(
    dbAs('driver1').ref('invites/tok4').set({
      email: 'z@example.org', role: 'driver', municipalityId: 'muniA',
      createdAt: T0, used: false,
    })
  );
  // invites are create-only for municipal admins (cleanup runs in the CF)
  await assertFails(dbAs('adminA').ref('invites/tok1').remove());
  await assertSucceeds(dbAs('super1').ref('invites/tok1/used').set(true));
  // consumed invite shape is accepted
  await assertSucceeds(
    dbAs('super1').ref('invites/tok9').set({
      email: 'q@example.org', role: 'driver', municipalityId: 'muniA',
      createdAt: T0, used: false,
    })
  );
});

// ===========================================================================
// DRIVER LOCATIONS (legacy node)
// ===========================================================================

test('driver_locations: only the assigned driver writes own location', async () => {
  await assertSucceeds(
    dbAs('driver1').ref('driver_locations/muniA/unit1/lat').set(14.6)
  );
  await assertFails(
    dbAs('driver2').ref('driver_locations/muniA/unit1/lat').set(14.6)
  );
  await assertFails(
    dbAs('driver1').ref('driver_locations/muniB/unit2/lat').set(14.6)
  );
  await assertSucceeds(dbAs('adminA').ref('driver_locations/muniA').get());
  await assertFails(dbAs('driver1').ref('driver_locations/muniA').get());
  await assertFails(dbAs(null).ref('driver_locations/muniA').get());
});
