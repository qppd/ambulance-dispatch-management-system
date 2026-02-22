import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/incident.dart';

void main() {
  group('IncidentSeverity', () {
    test('enum index ordering: critical=0, urgent=1, normal=2', () {
      expect(IncidentSeverity.critical.index, 0);
      expect(IncidentSeverity.urgent.index, 1);
      expect(IncidentSeverity.normal.index, 2);
    });

    test('displayName returns human-readable label', () {
      expect(IncidentSeverity.critical.displayName, 'Critical');
      expect(IncidentSeverity.urgent.displayName, 'Urgent');
      expect(IncidentSeverity.normal.displayName, 'Normal');
    });
  });

  group('IncidentStatus', () {
    test('isActive returns true for in-progress statuses', () {
      expect(IncidentStatus.pending.isActive, isTrue);
      expect(IncidentStatus.acknowledged.isActive, isTrue);
      expect(IncidentStatus.dispatched.isActive, isTrue);
      expect(IncidentStatus.enRoute.isActive, isTrue);
      expect(IncidentStatus.onScene.isActive, isTrue);
      expect(IncidentStatus.transporting.isActive, isTrue);
      expect(IncidentStatus.atHospital.isActive, isTrue);
    });

    test('isActive returns false for terminal statuses', () {
      expect(IncidentStatus.resolved.isActive, isFalse);
      expect(IncidentStatus.cancelled.isActive, isFalse);
    });

    test('displayName is not empty', () {
      for (final status in IncidentStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue);
      }
    });
  });

  group('Incident', () {
    final now = DateTime.now();

    Incident createTestIncident({
      String id = 'inc-1',
      IncidentSeverity severity = IncidentSeverity.urgent,
      IncidentStatus status = IncidentStatus.pending,
    }) {
      return Incident(
        id: id,
        municipalityId: 'mun-1',
        reporterId: 'user-1',
        reporterName: 'Juan Dela Cruz',
        reporterPhone: '09171234567',
        description: 'Cardiac arrest',
        incidentType: 'cardiac',
        address: '123 Main St, Brgy. Poblacion',
        latitude: 14.5995,
        longitude: 120.9842,
        severity: severity,
        status: status,
        createdAt: now,
      );
    }

    test('toJson serializes all fields', () {
      final incident = createTestIncident();
      final json = incident.toJson();

      expect(json['id'], 'inc-1');
      expect(json['municipalityId'], 'mun-1');
      expect(json['reporterId'], 'user-1');
      expect(json['reporterName'], 'Juan Dela Cruz');
      expect(json['severity'], 'urgent');
      expect(json['status'], 'pending');
      expect(json['latitude'], 14.5995);
      expect(json['longitude'], 120.9842);
      expect(json['incidentType'], 'cardiac');
    });

    test('fromJson deserializes correctly', () {
      final incident = createTestIncident();
      final json = incident.toJson();
      final deserialized = Incident.fromJson(json);

      expect(deserialized.id, incident.id);
      expect(deserialized.municipalityId, incident.municipalityId);
      expect(deserialized.reporterName, incident.reporterName);
      expect(deserialized.severity, incident.severity);
      expect(deserialized.status, incident.status);
      expect(deserialized.latitude, incident.latitude);
      expect(deserialized.longitude, incident.longitude);
    });

    test('copyWith updates only specified fields', () {
      final incident = createTestIncident();
      final updated = incident.copyWith(
        status: IncidentStatus.dispatched,
        assignedUnitId: 'unit-1',
        assignedDriverId: 'driver-1',
      );

      expect(updated.status, IncidentStatus.dispatched);
      expect(updated.assignedUnitId, 'unit-1');
      expect(updated.assignedDriverId, 'driver-1');
      // Unchanged fields
      expect(updated.id, incident.id);
      expect(updated.reporterName, incident.reporterName);
      expect(updated.severity, incident.severity);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'inc-2',
        'municipalityId': 'mun-1',
        'reporterId': 'user-2',
        'reporterName': 'Test',
        'reporterPhone': '123',
        'description': 'Test emergency',
        'incidentType': 'trauma',
        'address': 'Test address',
        'latitude': 14.0,
        'longitude': 121.0,
        'severity': 'normal',
        'status': 'pending',
        'createdAt': now.toIso8601String(),
      };
      final incident = Incident.fromJson(json);

      expect(incident.assignedUnitId, isNull);
      expect(incident.assignedDriverId, isNull);
      expect(incident.patientName, isNull);
      expect(incident.dispatchNotes, isNull);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = createTestIncident().copyWith(
        assignedUnitId: 'unit-x',
        assignedDriverId: 'driver-1',
        patientName: 'Maria Santos',
        patientAge: 45,
        dispatchNotes: 'Chest pain, shortness of breath',
      );
      final roundTripped = Incident.fromJson(original.toJson());

      expect(roundTripped.assignedUnitId, original.assignedUnitId);
      expect(roundTripped.assignedDriverId, original.assignedDriverId);
      expect(roundTripped.patientName, original.patientName);
      expect(roundTripped.patientAge, original.patientAge);
      expect(roundTripped.dispatchNotes, original.dispatchNotes);
    });
  });
}
