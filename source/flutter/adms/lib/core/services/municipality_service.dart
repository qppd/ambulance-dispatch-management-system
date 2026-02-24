import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Municipality service provider.
final municipalityServiceProvider = Provider<MunicipalityService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return MunicipalityService(dbRef);
});

/// Stream of all municipalities.
final allMunicipalitiesProvider = StreamProvider<List<Municipality>>((ref) {
  final service = ref.watch(municipalityServiceProvider);
  return service.watchAllMunicipalities();
});

/// Stream of a single municipality.
final municipalityProvider =
    StreamProvider.family<Municipality?, String>((ref, municipalityId) {
  final service = ref.watch(municipalityServiceProvider);
  return service.watchMunicipality(municipalityId);
});

/// Stream of ALL municipalities (active + inactive) for the management screen.
/// Unlike [allMunicipalitiesProvider], this does NOT filter by [Municipality.isActive].
final allMunicipalitiesManagementProvider =
    StreamProvider<List<Municipality>>((ref) {
  final service = ref.watch(municipalityServiceProvider);
  return service.watchAllMunicipalitiesForManagement();
});

// =============================================================================
// MUNICIPALITY SERVICE
// =============================================================================

/// Service for managing municipalities in Firebase Realtime Database.
///
/// RTDB structure:
/// ```
/// /municipalities/{municipalityId}/
///   ...Municipality fields (see municipality.dart)
/// ```
class MunicipalityService {
  final DatabaseReference _dbRef;

  MunicipalityService(this._dbRef);

  DatabaseReference get _municipalitiesRef =>
      _dbRef.child('municipalities');

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Register a new municipality.
  Future<Municipality> createMunicipality({
    required String id,
    required String name,
    required String province,
    required String region,
    String? contactNumber,
    String? email,
    double? centerLatitude,
    double? centerLongitude,
    String? emergencyHotline,
  }) async {
    final municipality = Municipality(
      id: id,
      name: name,
      province: province,
      region: region,
      contactNumber: contactNumber,
      email: email,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      emergencyHotline: emergencyHotline,
      createdAt: DateTime.now(),
    );

    await _municipalitiesRef.child(id).set(municipality.toJson());
    return municipality;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all municipalities (active only).
  Stream<List<Municipality>> watchAllMunicipalities() {
    return _municipalitiesRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Municipality>[];

      return data.entries
          .map((e) =>
              Municipality.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((m) => m.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  /// Watch ALL municipalities including inactive ones.
  /// Intended for the Super Admin management screen.
  Stream<List<Municipality>> watchAllMunicipalitiesForManagement() {
    return _municipalitiesRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Municipality>[];

      return data.entries
          .map((e) =>
              Municipality.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  /// Watch a single municipality.
  Stream<Municipality?> watchMunicipality(String municipalityId) {
    return _municipalitiesRef.child(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Municipality.fromJson(Map<String, dynamic>.from(data));
    });
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Update municipality details.
  Future<void> updateMunicipality({
    required String municipalityId,
    String? name,
    String? province,
    String? region,
    String? contactNumber,
    String? email,
    double? centerLatitude,
    double? centerLongitude,
    String? emergencyHotline,
    String? adminUid,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (province != null) updates['province'] = province;
    if (region != null) updates['region'] = region;
    if (contactNumber != null) updates['contactNumber'] = contactNumber;
    if (email != null) updates['email'] = email;
    if (centerLatitude != null) updates['centerLatitude'] = centerLatitude;
    if (centerLongitude != null) updates['centerLongitude'] = centerLongitude;
    if (emergencyHotline != null) updates['emergencyHotline'] = emergencyHotline;
    if (adminUid != null) updates['adminUid'] = adminUid;

    if (updates.isNotEmpty) {
      await _municipalitiesRef.child(municipalityId).update(updates);
    }
  }

  /// Update denormalized statistics.
  Future<void> updateStats({
    required String municipalityId,
    int? totalUnits,
    int? activeUnits,
    int? totalHospitals,
    int? totalDispatchers,
    int? totalDrivers,
  }) async {
    final updates = <String, dynamic>{};
    if (totalUnits != null) updates['totalUnits'] = totalUnits;
    if (activeUnits != null) updates['activeUnits'] = activeUnits;
    if (totalHospitals != null) updates['totalHospitals'] = totalHospitals;
    if (totalDispatchers != null) updates['totalDispatchers'] = totalDispatchers;
    if (totalDrivers != null) updates['totalDrivers'] = totalDrivers;

    if (updates.isNotEmpty) {
      await _municipalitiesRef.child(municipalityId).update(updates);
    }
  }

  /// Activate or deactivate a municipality.
  Future<void> setActive({
    required String municipalityId,
    required bool isActive,
  }) async {
    await _municipalitiesRef.child(municipalityId).update({
      'isActive': isActive,
    });
  }

  /// Delete a municipality.
  Future<void> deleteMunicipality(String municipalityId) async {
    await _municipalitiesRef.child(municipalityId).remove();
  }
}
