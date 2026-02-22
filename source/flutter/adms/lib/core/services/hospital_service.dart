import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Hospital service provider.
final hospitalServiceProvider = Provider<HospitalService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return HospitalService(dbRef);
});

/// Stream of all hospitals in a municipality.
final municipalityHospitalsProvider =
    StreamProvider.family<List<Hospital>, String>((ref, municipalityId) {
  final service = ref.watch(hospitalServiceProvider);
  return service.watchHospitals(municipalityId);
});

/// Stream of hospitals currently accepting patients.
final acceptingHospitalsProvider =
    StreamProvider.family<List<Hospital>, String>((ref, municipalityId) {
  final service = ref.watch(hospitalServiceProvider);
  return service.watchAcceptingHospitals(municipalityId);
});

/// Stream of a single hospital.
final hospitalProvider = StreamProvider.family<Hospital?,
    ({String municipalityId, String hospitalId})>((ref, params) {
  final service = ref.watch(hospitalServiceProvider);
  return service.watchHospital(params.municipalityId, params.hospitalId);
});

// =============================================================================
// HOSPITAL SERVICE
// =============================================================================

/// Service for managing hospitals in Firebase Realtime Database.
///
/// RTDB structure:
/// ```
/// /hospitals/{municipalityId}/{hospitalId}/
///   ...Hospital fields (see hospital.dart)
/// ```
class HospitalService {
  final DatabaseReference _dbRef;

  HospitalService(this._dbRef);

  DatabaseReference _hospitalsRef(String municipalityId) =>
      _dbRef.child('hospitals').child(municipalityId);

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Register a new hospital.
  Future<Hospital> createHospital({
    required String id,
    required String municipalityId,
    required String name,
    required String address,
    required String contactNumber,
    String? email,
    required double latitude,
    required double longitude,
    int totalBeds = 0,
    int emergencyCapacity = 0,
    List<String> specialties = const [],
    bool hasEmergencyRoom = true,
    bool hasSurgery = false,
    bool hasICU = false,
  }) async {
    final hospital = Hospital(
      id: id,
      municipalityId: municipalityId,
      name: name,
      address: address,
      contactNumber: contactNumber,
      email: email,
      latitude: latitude,
      longitude: longitude,
      totalBeds: totalBeds,
      availableBeds: totalBeds,
      emergencyCapacity: emergencyCapacity,
      specialties: specialties,
      hasEmergencyRoom: hasEmergencyRoom,
      hasSurgery: hasSurgery,
      hasICU: hasICU,
      createdAt: DateTime.now(),
    );

    await _hospitalsRef(municipalityId).child(id).set(hospital.toJson());
    return hospital;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all hospitals in a municipality.
  Stream<List<Hospital>> watchHospitals(String municipalityId) {
    return _hospitalsRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Hospital>[];

      return data.entries
          .map(
              (e) => Hospital.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((h) => h.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  /// Watch hospitals currently accepting patients.
  Stream<List<Hospital>> watchAcceptingHospitals(String municipalityId) {
    return _hospitalsRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Hospital>[];

      return data.entries
          .map(
              (e) => Hospital.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((h) => h.isActive && h.isAcceptingPatients)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  /// Watch a single hospital.
  Stream<Hospital?> watchHospital(String municipalityId, String hospitalId) {
    return _hospitalsRef(municipalityId)
        .child(hospitalId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Hospital.fromJson(Map<String, dynamic>.from(data));
    });
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Update hospital capacity (typically by hospital staff).
  Future<void> updateCapacity({
    required String municipalityId,
    required String hospitalId,
    required int availableBeds,
    required int currentEmergencyLoad,
  }) async {
    await _hospitalsRef(municipalityId).child(hospitalId).update({
      'availableBeds': availableBeds,
      'currentEmergencyLoad': currentEmergencyLoad,
      'lastCapacityUpdateAt': DateTime.now().toIso8601String(),
    });
  }

  /// Set whether hospital is accepting patients.
  Future<void> setAcceptingPatients({
    required String municipalityId,
    required String hospitalId,
    required bool isAccepting,
  }) async {
    await _hospitalsRef(municipalityId).child(hospitalId).update({
      'isAcceptingPatients': isAccepting,
      'lastCapacityUpdateAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update hospital details.
  Future<void> updateHospital({
    required String municipalityId,
    required String hospitalId,
    String? name,
    String? address,
    String? contactNumber,
    String? email,
    int? totalBeds,
    int? emergencyCapacity,
    List<String>? specialties,
    bool? hasEmergencyRoom,
    bool? hasSurgery,
    bool? hasICU,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (contactNumber != null) updates['contactNumber'] = contactNumber;
    if (email != null) updates['email'] = email;
    if (totalBeds != null) updates['totalBeds'] = totalBeds;
    if (emergencyCapacity != null) {
      updates['emergencyCapacity'] = emergencyCapacity;
    }
    if (specialties != null) updates['specialties'] = specialties;
    if (hasEmergencyRoom != null) updates['hasEmergencyRoom'] = hasEmergencyRoom;
    if (hasSurgery != null) updates['hasSurgery'] = hasSurgery;
    if (hasICU != null) updates['hasICU'] = hasICU;

    if (updates.isNotEmpty) {
      await _hospitalsRef(municipalityId).child(hospitalId).update(updates);
    }
  }

  /// Activate or deactivate a hospital.
  Future<void> setActive({
    required String municipalityId,
    required String hospitalId,
    required bool isActive,
  }) async {
    await _hospitalsRef(municipalityId).child(hospitalId).update({
      'isActive': isActive,
    });
  }

  /// Increment emergency load (incoming patient).
  Future<void> incrementEmergencyLoad({
    required String municipalityId,
    required String hospitalId,
  }) async {
    await _hospitalsRef(municipalityId)
        .child(hospitalId)
        .child('currentEmergencyLoad')
        .set(ServerValue.increment(1));

    await _hospitalsRef(municipalityId)
        .child(hospitalId)
        .child('lastCapacityUpdateAt')
        .set(DateTime.now().toIso8601String());
  }

  /// Delete a hospital.
  Future<void> deleteHospital({
    required String municipalityId,
    required String hospitalId,
  }) async {
    await _hospitalsRef(municipalityId).child(hospitalId).remove();
  }
}
