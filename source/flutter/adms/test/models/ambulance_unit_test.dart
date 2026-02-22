import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/ambulance_unit.dart';

void main() {
  group('UnitStatus', () {
    test('isBusy returns true for active statuses', () {
      expect(UnitStatus.enRoute.isBusy, isTrue);
      expect(UnitStatus.onScene.isBusy, isTrue);
      expect(UnitStatus.transporting.isBusy, isTrue);
      expect(UnitStatus.atHospital.isBusy, isTrue);
    });

    test('isBusy returns false for idle statuses', () {
      expect(UnitStatus.available.isBusy, isFalse);
      expect(UnitStatus.outOfService.isBusy, isFalse);
    });

    test('displayName is not empty', () {
      for (final status in UnitStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue);
      }
    });
  });

  group('UnitType', () {
    test('fullName provides descriptive name', () {
      expect(UnitType.als.fullName, 'Advanced Life Support');
      expect(UnitType.bls.fullName, 'Basic Life Support');
      expect(UnitType.micu.fullName, 'Mobile Intensive Care Unit');
      expect(UnitType.rescue.fullName, 'Rescue / Extrication');
    });
  });

  group('AmbulanceUnit', () {
    final now = DateTime.now();

    AmbulanceUnit createUnit({
      String id = 'unit-1',
      UnitStatus status = UnitStatus.available,
    }) {
      return AmbulanceUnit(
        id: id,
        municipalityId: 'mun-1',
        callSign: 'AMB-101',
        plateNumber: 'ABC-1234',
        type: UnitType.als,
        status: status,
        isActive: true,
        createdAt: now,
      );
    }

    test('toJson serializes correctly', () {
      final unit = createUnit();
      final json = unit.toJson();

      expect(json['id'], 'unit-1');
      expect(json['callSign'], 'AMB-101');
      expect(json['plateNumber'], 'ABC-1234');
      expect(json['type'], 'als');
      expect(json['status'], 'available');
      expect(json['isActive'], true);
    });

    test('fromJson deserializes correctly', () {
      final unit = createUnit();
      final json = unit.toJson();
      final deserialized = AmbulanceUnit.fromJson(json);

      expect(deserialized.id, unit.id);
      expect(deserialized.callSign, unit.callSign);
      expect(deserialized.type, unit.type);
      expect(deserialized.status, unit.status);
    });

    test('copyWith preserves unchanged fields', () {
      final unit = createUnit();
      final updated = unit.copyWith(
        status: UnitStatus.enRoute,
        currentIncidentId: 'inc-1',
      );

      expect(updated.status, UnitStatus.enRoute);
      expect(updated.currentIncidentId, 'inc-1');
      expect(updated.callSign, unit.callSign);
      expect(updated.plateNumber, unit.plateNumber);
      expect(updated.type, unit.type);
    });

    test('serialization handles driver assignment', () {
      final unit = createUnit().copyWith(
        assignedDriverId: 'driver-1',
        assignedDriverName: 'Pedro Santos',
      );
      final json = unit.toJson();
      final roundTripped = AmbulanceUnit.fromJson(json);

      expect(roundTripped.assignedDriverId, 'driver-1');
      expect(roundTripped.assignedDriverName, 'Pedro Santos');
    });

    test('serialization handles location data', () {
      final unit = createUnit().copyWith(
        latitude: 14.5995,
        longitude: 120.9842,
      );
      final json = unit.toJson();
      final roundTripped = AmbulanceUnit.fromJson(json);

      expect(roundTripped.latitude, 14.5995);
      expect(roundTripped.longitude, 120.9842);
    });
  });
}
