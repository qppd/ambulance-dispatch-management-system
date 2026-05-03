/// End-to-end integration test for the full ambulance dispatch lifecycle.
///
/// Flow tested:
///   Citizen reports emergency → Dispatcher acknowledges → Dispatcher dispatches
///   unit → Driver goes en-route → Driver arrives on-scene → Driver transports
///   patient → Driver completes transport → Dispatcher resolves incident.
///
/// This test uses fakes instead of Firebase so it can run offline.
library;

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:adms/core/models/models.dart';
import 'package:adms/core/services/dispatch_service.dart';
import 'package:adms/core/services/incident_service.dart';
import 'package:adms/core/services/unit_service.dart';

// =============================================================================
// FAKES
// =============================================================================

/// In-memory fake that records every multi-path update so we can assert on it.
class _FakeDatabaseReference implements DatabaseReference {
  final List<Map<String, dynamic>> updates = [];

  @override
  Future<void> update(Map<String, dynamic> value) async {
    updates.add(Map<String, dynamic>.from(value));
  }

  // -- Unused but required by interface ------------------------------------
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Minimal incident service fake that stores incidents in-memory.
class _FakeIncidentService implements IncidentService {
  final Map<String, Incident> _store = {};
  final _controller = StreamController<List<Incident>>.broadcast();

  Incident? get(String id) => _store[id];

  void _notify() => _controller.add(_store.values.toList());

  @override
  Future<Incident> reportIncident({
    required String municipalityId,
    required String reporterUid,
    required String reporterName,
    required String reporterPhone,
    required double latitude,
    required double longitude,
    required String address,
    required IncidentSeverity severity,
    String? description,
    String? patientName,
    int? patientAge,
    String? patientCondition,
  }) async {
    final id = 'inc_${_store.length + 1}';
    final incident = Incident(
      id: id,
      municipalityId: municipalityId,
      reporterId: reporterUid,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      status: IncidentStatus.pending,
      incidentType: 'emergency',
      description: description ?? 'Emergency reported',
      createdAt: DateTime.now(),
    );
    _store[id] = incident;
    _notify();
    return incident;
  }

  @override
  Future<void> acknowledgeIncident({
    required String municipalityId,
    required String incidentId,
    required String dispatcherUid,
    required String dispatcherName,
  }) async {
    final inc = _store[incidentId];
    if (inc != null) {
      _store[incidentId] = inc.copyWith(
        status: IncidentStatus.acknowledged,
        dispatcherId: dispatcherUid,
        dispatcherName: dispatcherName,
      );
      _notify();
    }
  }

  @override
  Stream<List<Incident>> watchActiveIncidents(String municipalityId) =>
      _controller.stream.map((list) =>
          list.where((i) => i.municipalityId == municipalityId).toList());

  @override
  Stream<Incident?> watchIncident(String municipalityId, String incidentId) =>
      _controller.stream.map((_) => _store[incidentId]);

  @override
  Stream<List<Incident>> watchIncidentsByReporter(String reporterUid) =>
      _controller.stream
          .map((list) => list.where((i) => i.reporterId == reporterUid).toList());

  // -- Stubs for unused methods -------------------------------------------
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Minimal unit service fake.
class _FakeUnitService implements UnitService {
  final Map<String, AmbulanceUnit> _store = {};

  void seedUnit(AmbulanceUnit unit) => _store[unit.id] = unit;

  AmbulanceUnit? get(String id) => _store[id];

  @override
  Future<void> updateStatus({
    required String municipalityId,
    required String unitId,
    required UnitStatus status,
  }) async {
    final u = _store[unitId];
    if (u != null) {
      _store[unitId] = u.copyWith(status: status);
    }
  }

  @override
  Future<void> updateLocation({
    required String municipalityId,
    required String unitId,
    required double latitude,
    required double longitude,
  }) async {
    final u = _store[unitId];
    if (u != null) {
      _store[unitId] = u.copyWith(latitude: latitude, longitude: longitude);
    }
  }

  @override
  Stream<List<AmbulanceUnit>> watchAvailableUnits(String municipalityId) =>
      Stream.value(
        _store.values.where((u) => u.status == UnitStatus.available).toList(),
      );

  // -- Stubs for unused methods -------------------------------------------
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// =============================================================================
// HELPERS
// =============================================================================

/// Default municipality used throughout the test.
const _municipalityId = 'mun_01';

User _makeUser({
  required String id,
  required UserRole role,
  String? municipalityId,
}) =>
    User(
      id: id,
      email: '$id@test.com',
      firstName: id,
      lastName: 'Test',
      role: role,
      municipalityId: municipalityId,
      isVerified: true,
      isActive: true,
      isApproved: true,
      createdAt: DateTime.now(),
    );

AmbulanceUnit _makeUnit({
  required String id,
  required String callSign,
  String? assignedDriverId,
}) =>
    AmbulanceUnit(
      id: id,
      municipalityId: _municipalityId,
      callSign: callSign,
      plateNumber: 'PLT-001',
      type: UnitType.als,
      status: UnitStatus.available,
      isActive: true,
      assignedDriverId: assignedDriverId,
      createdAt: DateTime.now(),
    );

// =============================================================================
// TEST
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dispatch lifecycle — end-to-end', () {
    late _FakeDatabaseReference fakeDb;
    late _FakeIncidentService fakeIncidentService;
    late _FakeUnitService fakeUnitService;
    late DispatchService dispatchService;

    final citizen = _makeUser(id: 'citizen_1', role: UserRole.citizen);
    final dispatchOperator = _makeUser(
        id: 'disp_1', role: UserRole.municipalAdmin, municipalityId: _municipalityId);
    final driver = _makeUser(
        id: 'driver_1', role: UserRole.driver, municipalityId: _municipalityId);
    final unit =
        _makeUnit(id: 'unit_1', callSign: 'ALS-01', assignedDriverId: driver.id);

    setUp(() {
      fakeDb = _FakeDatabaseReference();
      fakeIncidentService = _FakeIncidentService();
      fakeUnitService = _FakeUnitService();
      fakeUnitService.seedUnit(unit);
      dispatchService =
          DispatchService(fakeDb, fakeIncidentService, fakeUnitService);
    });

    testWidgets('full lifecycle from citizen report to resolution',
        (tester) async {
      // ---------------------------------------------------------------
      // 1. Citizen reports an incident
      // ---------------------------------------------------------------
      final reported = await fakeIncidentService.reportIncident(
        municipalityId: _municipalityId,
        reporterUid: citizen.id,
        reporterName: '${citizen.firstName} ${citizen.lastName}',
        reporterPhone: '0923-456-7890',
        latitude: -26.2041,
        longitude: 28.0473,
        address: 'N1 Highway',
        severity: IncidentSeverity.critical,
        description: 'Traffic collision on N1',
      );
      final incidentId = reported.id;

      var incident = fakeIncidentService.get(incidentId);
      expect(incident, isNotNull);
      expect(incident!.status, IncidentStatus.pending);

      // ---------------------------------------------------------------
      // 2. Dispatcher acknowledges the incident
      // ---------------------------------------------------------------
      await dispatchService.acknowledgeIncident(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        dispatcherUid: dispatchOperator.id,
        dispatcherName: '${dispatchOperator.firstName} ${dispatchOperator.lastName}',
      );

      incident = fakeIncidentService.get(incidentId);
      expect(incident!.status, IncidentStatus.acknowledged);
      expect(incident.dispatcherId, dispatchOperator.id);

      // ---------------------------------------------------------------
      // 3. Dispatcher dispatches a unit → atomic DB update
      // ---------------------------------------------------------------
      await dispatchService.dispatchUnit(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
        unitCallSign: unit.callSign,
        driverId: driver.id,
        driverName: '${driver.firstName} ${driver.lastName}',
        dispatcherUid: dispatchOperator.id,
        dispatcherName: '${dispatchOperator.firstName} ${dispatchOperator.lastName}',
      );

      expect(fakeDb.updates, hasLength(1));
      final dispatchUpdate = fakeDb.updates.first;
      expect(
        dispatchUpdate['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.dispatched.name,
      );
      expect(
        dispatchUpdate['units/$_municipalityId/${unit.id}/status'],
        UnitStatus.enRoute.toJson(),
      );

      // ---------------------------------------------------------------
      // 4. Driver marks en-route
      // ---------------------------------------------------------------
      await dispatchService.markEnRoute(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
      );

      expect(fakeDb.updates, hasLength(2));
      expect(
        fakeDb.updates[1]['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.enRoute.name,
      );

      // ---------------------------------------------------------------
      // 5. Driver arrives at scene
      // ---------------------------------------------------------------
      await dispatchService.markArrivedAtScene(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
      );

      expect(fakeDb.updates, hasLength(3));
      expect(
        fakeDb.updates[2]['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.onScene.name,
      );
      expect(
        fakeDb.updates[2]['units/$_municipalityId/${unit.id}/status'],
        UnitStatus.onScene.toJson(),
      );

      // ---------------------------------------------------------------
      // 6. Driver begins transport
      // ---------------------------------------------------------------
      await dispatchService.startTransport(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
        receivingFacility: 'City General',
      );

      expect(fakeDb.updates, hasLength(4));
      expect(
        fakeDb.updates[3]['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.transporting.name,
      );
      expect(
        fakeDb.updates[3]
            ['incidents/$_municipalityId/$incidentId/receivingFacility'],
        'City General',
      );

      // ---------------------------------------------------------------
      // 7. Driver completes transport
      // ---------------------------------------------------------------
      await dispatchService.markTransportComplete(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
      );

      expect(fakeDb.updates, hasLength(5));
      expect(
        fakeDb.updates[4]['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.resolved.name,
      );

      // ---------------------------------------------------------------
      // 8. Dispatcher resolves the incident (idempotent / adds notes)
      // ---------------------------------------------------------------
      await dispatchService.resolveIncident(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
        notes: 'Patient handed over to ER team',
      );

      expect(fakeDb.updates, hasLength(6));
      final resolveUpdate = fakeDb.updates[5];
      expect(
        resolveUpdate['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.resolved.name,
      );
      // Unit freed
      expect(
        resolveUpdate['units/$_municipalityId/${unit.id}/status'],
        UnitStatus.available.toJson(),
      );
      expect(
        resolveUpdate['units/$_municipalityId/${unit.id}/currentIncidentId'],
        isNull,
      );
      expect(
        resolveUpdate['incidents/$_municipalityId/$incidentId/notes'],
        'Patient handed over to ER team',
      );
    });

    testWidgets('cancel dispatch frees the assigned unit', (tester) async {
      // Setup: report + acknowledge + dispatch
      final reported2 = await fakeIncidentService.reportIncident(
        municipalityId: _municipalityId,
        reporterUid: citizen.id,
        reporterName: '${citizen.firstName} ${citizen.lastName}',
        reporterPhone: '0923-456-7890',
        latitude: -26.2041,
        longitude: 28.0473,
        address: 'Test location',
        severity: IncidentSeverity.urgent,
        description: 'Cancelled incident test',
      );
      final incidentId = reported2.id;

      await dispatchService.acknowledgeIncident(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        dispatcherUid: dispatchOperator.id,
        dispatcherName: '${dispatchOperator.firstName} ${dispatchOperator.lastName}',
      );

      await dispatchService.dispatchUnit(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
        unitCallSign: unit.callSign,
        driverId: driver.id,
        driverName: '${driver.firstName} ${driver.lastName}',
        dispatcherUid: dispatchOperator.id,
        dispatcherName: '${dispatchOperator.firstName} ${dispatchOperator.lastName}',
      );

      fakeDb.updates.clear();

      // Cancel the dispatch
      await dispatchService.cancelDispatch(
        municipalityId: _municipalityId,
        incidentId: incidentId,
        unitId: unit.id,
        reason: 'False alarm reported by bystander',
      );

      expect(fakeDb.updates, hasLength(1));
      final cancelUpdate = fakeDb.updates.first;
      expect(
        cancelUpdate['incidents/$_municipalityId/$incidentId/status'],
        IncidentStatus.cancelled.name,
      );
      // Unit should be freed
      expect(
        cancelUpdate['units/$_municipalityId/${unit.id}/status'],
        UnitStatus.available.toJson(),
      );
      expect(
        cancelUpdate['incidents/$_municipalityId/$incidentId/notes'],
        'False alarm reported by bystander',
      );
    });

    testWidgets('driver location update goes through dispatch service',
        (tester) async {
      await dispatchService.updateUnitLocation(
        municipalityId: _municipalityId,
        unitId: unit.id,
        latitude: -26.1050,
        longitude: 28.0560,
      );

      final updated = fakeUnitService.get(unit.id);
      expect(updated, isNotNull);
      expect(updated!.latitude, -26.1050);
      expect(updated.longitude, 28.0560);
    });
  });
}
