// Regression tests for the F1–F4 audit fixes and the router role guards.
//
// Each group locks in the specific bug that was fixed so it cannot silently
// return:
//   F1 — driver identity uses canonical `assignedDriverId`/`assignedDriverName`
//        keys; legacy `assignedUnitDriver*` keys are read-only fallbacks.
//   F2 — incident lifecycle is strictly linear and every transition carries a
//        dedicated timestamp field (validated by database.rules.json; here we
//        pin the model contract those rules rely on).
//   F3 — driver history queries filter on `assignedDriverId` (the canonical
//        key), which only works if fromJson populates it.
//   F4 — ePCR records persist every clinical field through a single
//        toJson()-shaped payload (atomic set()).
//   Router — role roots and sub-routes are only reachable by the owning role.

import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/models/incident.dart';
import 'package:adms/core/models/patient_care_report.dart';
import 'package:adms/core/models/user_role.dart';
import 'package:adms/core/router/app_router.dart';

void main() {
  group('F1 regression: canonical driver identity keys', () {
    test('fromJson reads assignedDriverId / assignedDriverName', () {
      final incident = Incident.fromJson({
        'id': 'inc-1',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'dispatched',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'assignedDriverId': 'driver-9',
        'assignedDriverName': 'Crew Nine',
      });
      expect(incident.assignedDriverId, 'driver-9');
      expect(incident.assignedDriverName, 'Crew Nine');
    });

    test('legacy assignedUnitDriver* keys still parse as a fallback', () {
      final incident = Incident.fromJson({
        'id': 'inc-2',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'dispatched',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'assignedUnitDriverId': 'driver-legacy',
        'assignedUnitDriverName': 'Legacy Crew',
      });
      expect(incident.assignedDriverId, 'driver-legacy');
      expect(incident.assignedDriverName, 'Legacy Crew');
    });

    test('canonical keys win when both old and new keys are present', () {
      final incident = Incident.fromJson({
        'id': 'inc-3',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'dispatched',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'assignedDriverId': 'canonical-driver',
        'assignedDriverName': 'Canonical Crew',
        'assignedUnitDriverId': 'stale-driver',
        'assignedUnitDriverName': 'Stale Crew',
      });
      expect(incident.assignedDriverId, 'canonical-driver');
      expect(incident.assignedDriverName, 'Canonical Crew');
    });

    test('toJson emits only the canonical keys (no legacy drift on write)', () {
      final incident = Incident(
        id: 'inc-4',
        municipalityId: 'mun-1',
        description: 'test',
        severity: IncidentSeverity.urgent,
        status: IncidentStatus.dispatched,
        incidentType: 'medical',
        latitude: 14.6,
        longitude: 120.9,
        assignedDriverId: 'driver-4',
        assignedDriverName: 'Crew Four',
        createdAt: DateTime(2024, 6, 1),
      );
      final json = incident.toJson();
      expect(json['assignedDriverId'], 'driver-4');
      expect(json['assignedDriverName'], 'Crew Four');
      expect(json.containsKey('assignedUnitDriverId'), isFalse);
      expect(json.containsKey('assignedUnitDriverName'), isFalse);
    });

    test('full round-trip preserves canonical driver identity', () {
      final original = Incident(
        id: 'inc-5',
        municipalityId: 'mun-1',
        description: 'test',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.transporting,
        incidentType: 'medical',
        latitude: 14.6,
        longitude: 120.9,
        assignedUnitId: 'unit-2',
        assignedUnitCallSign: 'AMB-02',
        assignedDriverId: 'driver-5',
        assignedDriverName: 'Crew Five',
        createdAt: DateTime(2024, 6, 1),
      );
      final decoded = Incident.fromJson(original.toJson());
      expect(decoded.assignedDriverId, original.assignedDriverId);
      expect(decoded.assignedDriverName, original.assignedDriverName);
      expect(decoded.assignedUnitId, original.assignedUnitId);
      expect(decoded.assignedUnitCallSign, original.assignedUnitCallSign);
    });
  });

  group('F2 regression: linear lifecycle + per-status timestamps', () {
    test('enum order matches the enforced lifecycle sequence', () {
      // database.rules.json validates transitions against this exact order;
      // reordering the enum would silently change the meaning of any
      // index-based comparison and confuse displayName-based queries.
      expect(IncidentStatus.values.map((s) => s.name).toList(), [
        'pending',
        'acknowledged',
        'dispatched',
        'enRoute',
        'onScene',
        'transporting',
        'atHospital',
        'resolved',
        'cancelled',
      ]);
    });

    test('every in-flight status has a dedicated timestamp field', () {
      final incident = Incident.fromJson({
        'id': 'inc-6',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'atHospital',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'acknowledgedAt': '2024-06-01T12:01:00.000',
        'dispatchedAt': '2024-06-01T12:02:00.000',
        'enRouteAt': '2024-06-01T12:03:00.000',
        'onSceneAt': '2024-06-01T12:08:00.000',
        'transportingAt': '2024-06-01T12:15:00.000',
        'atHospitalAt': '2024-06-01T12:25:00.000',
        'resolvedAt': '2024-06-01T12:40:00.000',
      });
      expect(incident.acknowledgedAt, isNotNull);
      expect(incident.dispatchedAt, isNotNull);
      expect(incident.enRouteAt, isNotNull);
      expect(incident.onSceneAt, isNotNull);
      expect(incident.transportingAt, isNotNull);
      expect(incident.atHospitalAt, isNotNull);
      expect(incident.resolvedAt, isNotNull);
      // Chronological sanity: the lifecycle timestamps are strictly ordered.
      expect(incident.acknowledgedAt!.isBefore(incident.dispatchedAt!), isTrue);
      expect(incident.dispatchedAt!.isBefore(incident.enRouteAt!), isTrue);
      expect(incident.enRouteAt!.isBefore(incident.onSceneAt!), isTrue);
      expect(incident.onSceneAt!.isBefore(incident.transportingAt!), isTrue);
      expect(incident.transportingAt!.isBefore(incident.atHospitalAt!), isTrue);
      expect(incident.atHospitalAt!.isBefore(incident.resolvedAt!), isTrue);
    });

    test('timestamps survive the toJson/fromJson round-trip', () {
      final now = DateTime(2024, 6, 1, 12, 30).toIso8601String();
      final incident = Incident.fromJson({
        'id': 'inc-7',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'normal',
        'status': 'enRoute',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'enRouteAt': now,
      });
      final decoded = Incident.fromJson(incident.toJson());
      expect(decoded.enRouteAt, incident.enRouteAt);
    });

    test('isActive is false only for resolved/cancelled', () {
      expect(IncidentStatus.pending.isActive, isTrue);
      expect(IncidentStatus.acknowledged.isActive, isTrue);
      expect(IncidentStatus.dispatched.isActive, isTrue);
      expect(IncidentStatus.enRoute.isActive, isTrue);
      expect(IncidentStatus.onScene.isActive, isTrue);
      expect(IncidentStatus.transporting.isActive, isTrue);
      expect(IncidentStatus.atHospital.isActive, isTrue);
      expect(IncidentStatus.resolved.isActive, isFalse);
      expect(IncidentStatus.cancelled.isActive, isFalse);
    });
  });

  group('F3 regression: driver queries rely on the canonical key', () {
    // IncidentService.watchIncidentsByDriver/_filteredDriverIncidents query
    // with orderByChild('assignedDriverId'). That query returns nothing for
    // legacy-written incidents unless fromJson falls back to the old key —
    // pin both halves of the contract.
    test('assignedDriverId is populated for canonical records', () {
      final incident = Incident.fromJson({
        'id': 'inc-8',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'enRoute',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'assignedDriverId': 'driver-filter',
      });
      expect(incident.assignedDriverId, 'driver-filter');
    });

    test('legacy records still surface under the canonical filter value', () {
      final incident = Incident.fromJson({
        'id': 'inc-9',
        'municipalityId': 'mun-1',
        'description': 'test',
        'severity': 'urgent',
        'status': 'enRoute',
        'incidentType': 'medical',
        'createdAt': '2024-06-01T12:00:00.000',
        'assignedUnitDriverId': 'driver-legacy-filter',
      });
      expect(incident.assignedDriverId, 'driver-legacy-filter');
    });
  });

  group('F4 regression: ePCR atomic persistence payload', () {
    test('toJson carries every clinical field written on create', () {
      final report = PatientCareReport(
        id: 'pcr-1',
        municipalityId: 'mun-1',
        incidentId: 'inc-1',
        unitId: 'unit-1',
        createdByUid: 'driver-1',
        createdByName: 'Crew One',
        patientFirstName: 'Maria',
        patientLastName: 'Santos',
        patientAge: 45,
        patientGender: 'female',
        patientAddress: 'Brgy. Poblacion',
        patientContactNumber: '09171234567',
        chiefComplaint: 'Chest pain',
        historyOfPresentIllness: 'Sudden onset',
        allergies: ['Penicillin'],
        medications: ['Metformin'],
        pastMedicalHistory: ['Hypertension'],
        systolicBP: 120,
        diastolicBP: 80,
        heartRate: 92,
        respiratoryRate: 18,
        oxygenSaturation: 97.5,
        temperature: 37.2,
        levelOfConsciousness: 'Alert',
        treatmentsAdministered: ['Oxygen therapy'],
        medicationsGiven: ['Aspirin 300mg'],
        procedureNotes: 'IV access established',
        destinationHospitalId: 'hosp-1',
        destinationHospitalName: 'General Hospital',
        receivingStaffName: 'Dr. Cruz',
        handoverTime: DateTime(2024, 6, 1, 13, 0),
        handoverNotes: 'Turned over stable',
        createdAt: DateTime(2024, 6, 1, 12, 0),
      );

      final json = report.toJson();
      // createReport persists with a single set(report.toJson()); every one of
      // these keys must be present or the field is silently lost on create.
      for (final key in [
        'id',
        'municipalityId',
        'incidentId',
        'unitId',
        'createdByUid',
        'createdByName',
        'patientFirstName',
        'patientLastName',
        'patientAge',
        'patientGender',
        'patientAddress',
        'patientContactNumber',
        'chiefComplaint',
        'historyOfPresentIllness',
        'allergies',
        'medications',
        'pastMedicalHistory',
        'systolicBP',
        'diastolicBP',
        'heartRate',
        'respiratoryRate',
        'oxygenSaturation',
        'temperature',
        'levelOfConsciousness',
        'treatmentsAdministered',
        'medicationsGiven',
        'procedureNotes',
        'destinationHospitalId',
        'destinationHospitalName',
        'receivingStaffName',
        'handoverTime',
        'handoverNotes',
        'createdAt',
      ]) {
        expect(json.containsKey(key), isTrue, reason: 'missing key: $key');
      }
    });

    test('full round-trip preserves every clinical field', () {
      final report = PatientCareReport(
        id: 'pcr-2',
        municipalityId: 'mun-1',
        incidentId: 'inc-2',
        unitId: 'unit-1',
        createdByUid: 'driver-1',
        createdByName: 'Crew One',
        patientFirstName: 'Juan',
        patientLastName: 'Dela Cruz',
        patientAge: 60,
        patientGender: 'male',
        chiefComplaint: 'Difficulty breathing',
        systolicBP: 140,
        diastolicBP: 90,
        heartRate: 110,
        respiratoryRate: 24,
        oxygenSaturation: 91.0,
        temperature: 38.5,
        levelOfConsciousness: 'Verbal',
        handoverTime: DateTime(2024, 6, 1, 14, 0),
        createdAt: DateTime(2024, 6, 1, 12, 0),
      );
      final decoded = PatientCareReport.fromJson(report.toJson());
      expect(decoded.systolicBP, 140);
      expect(decoded.diastolicBP, 90);
      expect(decoded.heartRate, 110);
      expect(decoded.respiratoryRate, 24);
      expect(decoded.oxygenSaturation, 91.0);
      expect(decoded.temperature, 38.5);
      expect(decoded.levelOfConsciousness, 'Verbal');
      expect(decoded.handoverTime, report.handoverTime);
      expect(decoded.patientFullName, 'Juan Dela Cruz');
    });
  });

  group('Router regression: role-scoped locations', () {
    test('auth and welcome locations are never role-scoped', () {
      for (final loc in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.staffLogin,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
        AppRoutes.pendingApproval,
        AppRoutes.citizenLogin, // auth route nested under /citizen/
      ]) {
        expect(
          AppRoutes.roleForLocation(loc),
          isNull,
          reason: '$loc must stay reachable for everyone',
        );
      }
    });

    test('role roots map to their owning role', () {
      expect(
        AppRoutes.roleForLocation(AppRoutes.superAdminHome),
        UserRole.superAdmin,
      );
      expect(
        AppRoutes.roleForLocation(AppRoutes.municipalAdminHome),
        UserRole.municipalAdmin,
      );
      expect(AppRoutes.roleForLocation(AppRoutes.driverHome), UserRole.driver);
      expect(
        AppRoutes.roleForLocation(AppRoutes.citizenHome),
        UserRole.citizen,
      );
    });

    test('role sub-routes inherit the root role', () {
      expect(
        AppRoutes.roleForLocation(AppRoutes.userManagement),
        UserRole.superAdmin,
      );
      expect(
        AppRoutes.roleForLocation(AppRoutes.systemSettings),
        UserRole.superAdmin,
      );
      expect(AppRoutes.roleForLocation(AppRoutes.reports), UserRole.superAdmin);
      expect(
        AppRoutes.roleForLocation(AppRoutes.municipalityManagement),
        UserRole.superAdmin,
      );
      expect(
        AppRoutes.roleForLocation(AppRoutes.citizenIncidentTracking),
        UserRole.citizen,
      );
    });

    test('getHomeRoute and roleForLocation are inverse-consistent', () {
      for (final role in UserRole.values) {
        final home = AppRoutes.getHomeRoute(role);
        expect(
          AppRoutes.roleForLocation(home),
          role,
          reason: 'home of ${role.name} must be guarded by ${role.name}',
        );
      }
    });
  });
}
