import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/municipality.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Citizen service provider.
final citizenServiceProvider = Provider<CitizenService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return CitizenService(dbRef);
});

/// Emergency contacts stream for a user.
final citizenEmergencyContactsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(citizenServiceProvider);
  return service.watchEmergencyContacts();
});

/// Medical information stream for the current citizen.
final citizenMedicalInfoProvider = StreamProvider<Map<String, dynamic>?>(
  (ref) {
    final service = ref.watch(citizenServiceProvider);
    return service.watchMedicalInfo();
  },
);

/// Notification preferences stream for the current citizen.
final citizenNotificationPrefsProvider = StreamProvider<Map<String, dynamic>?>(
  (ref) {
    final service = ref.watch(citizenServiceProvider);
    return service.watchNotificationPrefs();
  },
);

// =============================================================================
// CITIZEN SERVICE
// =============================================================================

/// Service for managing citizen-specific data in Firebase Realtime Database.
///
/// RTDB structure:
/// ```
/// /citizen/{userId}/
///   emergencyContacts: [...list of {name, phone, relation}]
///   medicalInfo: {bloodType, allergies, conditions, medications, physicianName, physicianPhone}
///   notificationPrefs: {incidentUpdates, systemAnnouncements}
/// ```
class CitizenService {
  final DatabaseReference _dbRef;

  CitizenService(this._dbRef);

  String? get _currentUserId => _dbRef.root.key;

  DatabaseReference get _citizenRef => _dbRef.child('citizen');

  DatabaseReference _userCitizenRef(String uid) =>
      _citizenRef.child(uid);

  // ===========================================================================
  // EMERGENCY CONTACTS
  // ===========================================================================

  /// Stream of emergency contacts for the current user.
  /// Returns a list of `{key, name, phone, relation}` maps so the UI can
  /// address each child by its push key for edit/delete operations.
  Stream<List<Map<String, dynamic>>> watchEmergencyContacts() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(<Map<String, dynamic>>[]);
    return _userCitizenRef(uid).child('emergencyContacts').onValue.map(
          (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null || data.isEmpty) return <Map<String, dynamic>>[];
        return data.entries.map((e) {
          final val = Map<String, dynamic>.from(e.value as Map);
          val['key'] = e.key as String;
          return val;
        }).toList();
      },
    );
  }

  /// Add an emergency contact.
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _userCitizenRef(uid).child('emergencyContacts').push().set({
      'name': name,
      'phone': phone,
      'relation': relation,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing emergency contact.
  Future<void> updateEmergencyContact({
    required String contactKey,
    required String name,
    required String phone,
    required String relation,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _userCitizenRef(uid)
        .child('emergencyContacts')
        .child(contactKey)
        .update({'name': name, 'phone': phone, 'relation': relation});
  }

  /// Delete an emergency contact.
  Future<void> deleteEmergencyContact(String contactKey) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _userCitizenRef(uid).child('emergencyContacts').child(contactKey).remove();
  }

  // ===========================================================================
  // MEDICAL INFORMATION
  // ===========================================================================

  /// Stream of current citizen's medical info.
  Stream<Map<String, dynamic>?> watchMedicalInfo() {
    final uid = _currentUserId;
    if (uid == null) return Stream<Map<String, dynamic>?>.value(null);
    return _userCitizenRef(uid).child('medicalInfo').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  /// Save or update medical information.
  Future<void> saveMedicalInfo({
    String? bloodType,
    String? allergies,
    String? conditions,
    String? medications,
    String? physicianName,
    String? physicianPhone,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _userCitizenRef(uid).child('medicalInfo').set({
      if (bloodType != null && bloodType.isNotEmpty) 'bloodType': bloodType,
      if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
      if (conditions != null && conditions.isNotEmpty) 'conditions': conditions,
      if (medications != null && medications.isNotEmpty) 'medications': medications,
      if (physicianName != null && physicianName.isNotEmpty) 'physicianName': physicianName,
      if (physicianPhone != null && physicianPhone.isNotEmpty) 'physicianPhone': physicianPhone,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ===========================================================================
  // NOTIFICATION PREFERENCES
  // ===========================================================================

  /// Stream of current citizen's notification preferences.
  Stream<Map<String, dynamic>?> watchNotificationPrefs() {
    final uid = _currentUserId;
    if (uid == null) return Stream<Map<String, dynamic>?>.value(null);
    return _userCitizenRef(uid).child('notificationPrefs').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  /// Save notification preferences.
  Future<void> saveNotificationPrefs({
    required bool incidentUpdates,
    required bool systemAnnouncements,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _userCitizenRef(uid).child('notificationPrefs').set({
      'incidentUpdates': incidentUpdates,
      'systemAnnouncements': systemAnnouncements,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ===========================================================================
  // MUNICIPALITY LOCATION AUTO-DETECTION
  // ===========================================================================

  /// Find the nearest active municipality based on lat/lng.
  /// Uses the Haversine formula to compute distance to each municipality's
  /// center coordinate. Falls back to the first active municipality
  /// alphabetically if no centers are available.
  Future<String?> findNearestMunicipality({
    required double latitude,
    required double longitude,
  }) async {
    final snapshot = await _dbRef.child('municipalities').get();
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;

    Municipality? nearest;
    double? nearestDist;

    for (final entry in data.entries) {
      final m = Municipality.fromJson(Map<String, dynamic>.from(entry.value as Map));
      if (!m.isActive || m.centerLatitude == null || m.centerLongitude == null) continue;
      final dist = _haversineDistance(
        lat1: latitude,
        lon1: longitude,
        lat2: m.centerLatitude!,
        lon2: m.centerLongitude!,
      );
      if (nearestDist == null || dist < nearestDist) {
        nearestDist = dist;
        nearest = m;
      }
    }

    // Fallback: return first active municipality
    if (nearest == null) {
      for (final entry in data.entries) {
        final m = Municipality.fromJson(Map<String, dynamic>.from(entry.value as Map));
        if (m.isActive) return m.id;
      }
    }

    return nearest?.id;
  }

  /// Haversine formula: distance in km between two lat/lon points.
  double _haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final lat1Rad = lat1 * math.pi / 180.0;
    final lat2Rad = lat2 * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.asin(math.sqrt(a));
  }
}
