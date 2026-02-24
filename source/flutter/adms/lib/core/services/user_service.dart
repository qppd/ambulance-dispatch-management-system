import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// User service provider.
final userServiceProvider = Provider<UserService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return UserService(dbRef);
});

/// Stream of ALL users across the entire system (Super Admin only).
final allUsersProvider = StreamProvider<List<User>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.watchAllUsers();
});

/// Stream of users filtered by role.
final usersByRoleProvider =
    StreamProvider.family<List<User>, UserRole>((ref, role) {
  final service = ref.watch(userServiceProvider);
  return service.watchUsersByRole(role);
});

/// Stream of users belonging to a specific municipality.
final municipalityUsersProvider =
    StreamProvider.family<List<User>, String>((ref, municipalityId) {
  final service = ref.watch(userServiceProvider);
  return service.watchUsersByMunicipality(municipalityId);
});

/// Stream of a single user by UID.
final userByIdProvider =
    StreamProvider.family<User?, String>((ref, uid) {
  final service = ref.watch(userServiceProvider);
  return service.watchUser(uid);
});

// =============================================================================
// USER SERVICE
// =============================================================================

/// Service for reading and managing user records from Firebase RTDB.
///
/// RTDB structure:
/// ```
/// /users/{uid}/
///   id, email, firstName, lastName, role, municipalityId,
///   isVerified, isActive, isApproved, createdAt, lastLoginAt, ...
/// ```
class UserService {
  final DatabaseReference _dbRef;

  UserService(this._dbRef);

  DatabaseReference get _usersRef => _dbRef.child('users');

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Stream all users (Super Admin only — unfiltered).
  Stream<List<User>> watchAllUsers() {
    return _usersRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <User>[];
      return data.entries
          .map((e) {
            try {
              final map = Map<String, dynamic>.from(e.value as Map);
              // Ensure the id field is set from the key if missing
              map['id'] ??= e.key as String;
              return User.fromJson(map);
            } catch (_) {
              return null;
            }
          })
          .whereType<User>()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Stream users filtered by role.
  Stream<List<User>> watchUsersByRole(UserRole role) {
    return watchAllUsers().map(
      (users) => users.where((u) => u.role == role).toList(),
    );
  }

  /// Stream users belonging to a specific municipality.
  Stream<List<User>> watchUsersByMunicipality(String municipalityId) {
    return watchAllUsers().map(
      (users) =>
          users.where((u) => u.municipalityId == municipalityId).toList(),
    );
  }

  /// Watch a single user by UID.
  Stream<User?> watchUser(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      try {
        final map = Map<String, dynamic>.from(data);
        map['id'] ??= uid;
        return User.fromJson(map);
      } catch (_) {
        return null;
      }
    });
  }

  // ===========================================================================
  // WRITE
  // ===========================================================================

  /// Approve a pending user account.
  Future<void> approveUser(String uid) async {
    await _usersRef.child(uid).update({'isApproved': true});
  }

  /// Deactivate (soft-delete) a user account.
  Future<void> deactivateUser(String uid) async {
    await _usersRef.child(uid).update({'isActive': false});
  }

  /// Reactivate a previously deactivated account.
  Future<void> reactivateUser(String uid) async {
    await _usersRef.child(uid).update({'isActive': true});
  }

  /// Update a user's role (Super Admin only).
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _usersRef.child(uid).update({'role': role.toJson()});
  }

  /// Update a user's municipality assignment.
  Future<void> updateUserMunicipality(
      String uid, String? municipalityId, String? municipalityName) async {
    await _usersRef.child(uid).update({
      'municipalityId': municipalityId,
      'municipalityName': municipalityName,
    });
  }
}
