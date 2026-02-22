import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/municipality.dart';

void main() {
  group('Municipality', () {
    final now = DateTime.now();

    Municipality createMunicipality() {
      return Municipality(
        id: 'mun-1',
        name: 'City of Manila',
        province: 'Metro Manila',
        region: 'NCR',
        contactNumber: '02-5271-1234',
        centerLatitude: 14.5995,
        centerLongitude: 120.9842,
        emergencyHotline: '911',
        totalUnits: 12,
        activeUnits: 8,
        totalHospitals: 5,
        totalDispatchers: 6,
        totalDrivers: 15,
        isActive: true,
        createdAt: now,
      );
    }

    test('toJson serializes all fields', () {
      final muni = createMunicipality();
      final json = muni.toJson();

      expect(json['id'], 'mun-1');
      expect(json['name'], 'City of Manila');
      expect(json['province'], 'Metro Manila');
      expect(json['region'], 'NCR');
      expect(json['totalUnits'], 12);
      expect(json['activeUnits'], 8);
      expect(json['totalHospitals'], 5);
      expect(json['isActive'], true);
    });

    test('fromJson round-trip', () {
      final original = createMunicipality();
      final roundTripped = Municipality.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.province, original.province);
      expect(roundTripped.totalUnits, original.totalUnits);
      expect(roundTripped.activeUnits, original.activeUnits);
      expect(roundTripped.totalHospitals, original.totalHospitals);
      expect(roundTripped.emergencyHotline, original.emergencyHotline);
    });

    test('copyWith updates specified fields', () {
      final muni = createMunicipality();
      final updated = muni.copyWith(
        activeUnits: 10,
        totalDrivers: 20,
        isActive: false,
      );

      expect(updated.activeUnits, 10);
      expect(updated.totalDrivers, 20);
      expect(updated.isActive, false);
      // Unchanged
      expect(updated.name, muni.name);
      expect(updated.totalUnits, muni.totalUnits);
    });

    test('fromJson handles defaults for missing optional fields', () {
      final json = {
        'id': 'mun-2',
        'name': 'Test City',
        'province': 'Test Province',
        'region': 'Test Region',
        'contactNumber': '123',
        'centerLatitude': 14.0,
        'centerLongitude': 121.0,
        'createdAt': now.toIso8601String(),
      };
      final muni = Municipality.fromJson(json);

      expect(muni.totalUnits, 0);
      expect(muni.activeUnits, 0);
      expect(muni.totalHospitals, 0);
      expect(muni.isActive, true);
      expect(muni.adminUid, isNull);
      expect(muni.emergencyHotline, isNull);
    });
  });
}
