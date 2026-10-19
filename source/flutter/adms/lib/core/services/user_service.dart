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
///
/// Reads the `/users` root, which database.rules.json restricts to
/// superAdmin — municipal admin screens must use
/// [municipalityUsersProvider] instead.
final allUsersProvider = StreamProvider<List<User>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.watchAllUsers();
});

/// Stream of users belonging to a specific municipality.
///
/// Queries `/users` directly with `orderByChild('municipalityId').equalTo()`
/// rather than reading a mirror. (The former `usersByRoleProvider` and
/// `userByIdProvider` were removed: nothing consumed them, and they queried
/// the `/users` root that is now gated, so any reuse from a municipal admin
/// screen would silently fail with PERMISSION_DENIED.)
final municipalityUsersProvider = StreamProvider.family<List<User>, String>((
  ref,
  municipalityId,
) {
  final service = ref.watch(userServiceProvider);
  return service.watchUsersByMunicipality(municipalityId);
});

/// Realtime notification preferences for a single user (any non-citizen role).
///
/// Reads `/users/{uid}/notificationPrefs`, which mirrors the shape used under
/// `/citizen/{uid}/notificationPrefs`: `{incidentUpdates, systemAnnouncements,
/// updatedAt}`. Citizens keep their preferences under the citizen service's
/// own provider instead; the shared Notification Settings screen dispatches
/// between the two based on the signed-in user's role.
final userNotificationPrefsProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  final service = ref.watch(userServiceProvider);
  return service.watchNotificationPrefs(uid);
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

  List<User> _parseUsersSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return <User>[];

    return data.entries
        .map((e) {
          try {
            final map = Map<String, dynamic>.from(e.value as Map);
            map['id'] ??= e.key as String;
            return User.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<User>()
        .toList();
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Stream all users (Super Admin only — unfiltered).
  Stream<List<User>> watchAllUsers() {
    return _usersRef.onValue.map((event) {
      return _parseUsersSnapshot(event.snapshot)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Stream users belonging to a specific municipality.
  ///
  /// Queries `/users` pinned to the municipality. RTDB rules do not filter
  /// rows, so a plain municipality-filtered query could not simply be handed
  /// to municipal admins without exposing every user in the system — but
  /// rules can inspect the query itself. The `.read` rule on `/users` requires
  /// `query.orderByChild === 'municipalityId'` AND `query.equalTo` equal to
  /// the caller's own municipality, so an admin can only ever receive its own
  /// municipality's records; an unbounded read is denied outright.
  ///
  /// This replaces the earlier `/municipality_users` mirror, which only ever
  /// held data if the `onUserProfileWritten` Cloud Function was deployed.
  /// Reading the source of truth leaves no second copy to drift: a driver who
  /// is deactivated disappears from this list immediately instead of lingering
  /// in a stale mirror.
  Stream<List<User>> watchUsersByMunicipality(String municipalityId) {
    return _dbRef
        .child('users')
        .orderByChild('municipalityId')
        .equalTo(municipalityId)
        .onValue
        .map(
          (event) =>
              _parseUsersSnapshot(event.snapshot)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
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
    String uid,
    String? municipalityId,
    String? municipalityName,
  ) async {
    await _usersRef.child(uid).update({
      'municipalityId': municipalityId,
      'municipalityName': municipalityName,
    });
  }

  /// Update user profile fields (name, phone).
  Future<void> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (updates.isNotEmpty) {
      await _usersRef.child(uid).update(updates);
    }
  }

  /// Save FCM token for a user.
  Future<void> saveFcmToken(String uid, String token) async {
    await _usersRef.child(uid).update({'fcmToken': token});
  }

  /// Realtime stream of a user's notification preferences.
  /// RTDB path: /users/{uid}/notificationPrefs
  Stream<Map<String, dynamic>?> watchNotificationPrefs(String uid) {
    return _usersRef.child(uid).child('notificationPrefs').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  /// Save notification preferences (RTDB path: /users/{uid}/notificationPrefs).
  Future<void> saveNotificationPrefs({
    required String uid,
    required bool incidentUpdates,
    required bool systemAnnouncements,
  }) async {
    await _usersRef.child(uid).child('notificationPrefs').set({
      'incidentUpdates': incidentUpdates,
      'systemAnnouncements': systemAnnouncements,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
