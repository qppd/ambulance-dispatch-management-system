import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/hospital.dart';

void main() {
  group('Hospital', () {
    final now = DateTime.now();

    Hospital createHospital({
      int totalBeds = 100,
      int availableBeds = 30,
      int emergencyCapacity = 20,
      int currentEmergencyLoad = 5,
    }) {
      return Hospital(
        id: 'hosp-1',
        municipalityId: 'mun-1',
        name: 'Philippine General Hospital',
        address: '123 Taft Ave, Manila',
        contactNumber: '02-1234567',
        latitude: 14.5788,
        longitude: 120.9853,
        totalBeds: totalBeds,
        availableBeds: availableBeds,
        emergencyCapacity: emergencyCapacity,
        currentEmergencyLoad: currentEmergencyLoad,
        specialties: ['Cardiology', 'Trauma', 'Pediatrics'],
        hasEmergencyRoom: true,
        hasSurgery: true,
        hasICU: true,
        isActive: true,
        isAcceptingPatients: true,
        createdAt: now,
      );
    }

    test('emergencyLoadFactor computes correctly', () {
      final hospital = createHospital(
        emergencyCapacity: 20,
        currentEmergencyLoad: 15,
      );
      expect(hospital.emergencyLoadFactor, 0.75);
    });

    test('emergencyLoadFactor returns 1.0 when capacity is 0', () {
      final hospital = createHospital(
        emergencyCapacity: 0,
        currentEmergencyLoad: 0,
      );
      expect(hospital.emergencyLoadFactor, 1.0);
    });

    test('isNearCapacity is true when load > 80%', () {
      final hospital = createHospital(
        emergencyCapacity: 10,
        currentEmergencyLoad: 9,
      );
      expect(hospital.isNearCapacity, isTrue);
    });

    test('isNearCapacity is false when load <= 80%', () {
      final hospital = createHospital(
        emergencyCapacity: 10,
        currentEmergencyLoad: 7,
      );
      expect(hospital.isNearCapacity, isFalse);
    });

    test('toJson serializes all fields', () {
      final hospital = createHospital();
      final json = hospital.toJson();

      expect(json['id'], 'hosp-1');
      expect(json['name'], 'Philippine General Hospital');
      expect(json['totalBeds'], 100);
      expect(json['availableBeds'], 30);
      expect(json['specialties'], ['Cardiology', 'Trauma', 'Pediatrics']);
      expect(json['hasEmergencyRoom'], true);
      expect(json['isAcceptingPatients'], true);
    });

    test('fromJson round-trip', () {
      final original = createHospital();
      final roundTripped = Hospital.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.totalBeds, original.totalBeds);
      expect(roundTripped.availableBeds, original.availableBeds);
      expect(roundTripped.specialties, original.specialties);
      expect(roundTripped.hasICU, original.hasICU);
    });

    test('copyWith updates specified fields', () {
      final hospital = createHospital();
      final updated = hospital.copyWith(
        availableBeds: 10,
        isAcceptingPatients: false,
      );

      expect(updated.availableBeds, 10);
      expect(updated.isAcceptingPatients, false);
      expect(updated.name, hospital.name);
      expect(updated.totalBeds, hospital.totalBeds);
    });
  });
}
