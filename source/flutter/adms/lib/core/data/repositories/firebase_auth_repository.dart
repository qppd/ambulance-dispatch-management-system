import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_database/firebase_database.dart';

import '../../models/models.dart';
import 'auth_repository.dart';

/// Firebase implementation of [AuthRepository].
///
/// Uses Firebase Authentication for identity management and
/// Firebase Realtime Database for user profile/role storage.
///
/// RTDB User Profile Schema:
/// ```
/// /users/{uid}/
///   email: String
///   firstName: String
///   lastName: String
///   phoneNumber: String?
///   role: String (enum name)
///   municipalityId: String?
///   municipalityName: String?
///   hospitalId: String?
///   hospitalName: String?
///   avatarUrl: String?
///   isVerified: bool
///   isActive: bool
///   isApproved: bool
///   createdAt: String (ISO 8601)
///   lastLoginAt: String? (ISO 8601)
/// ```
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final DatabaseReference _dbRef;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _dbRef = (database ?? FirebaseDatabase.instance).ref();

  /// Reference to the /users node in RTDB.
  DatabaseReference get _usersRef => _dbRef.child('users');

  // ===========================================================================
  // AUTH STATE STREAM
  // ===========================================================================

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _buildUserFromFirebase(fbUser);
    });
  }

  @override
  User? get currentUser {
    // This is a synchronous getter — returns cached user or null.
    // For a fresh user, use authStateChanges stream.
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    // Note: This won't have RTDB profile data.
    // Use getUserProfile() for the full user object.
    return null;
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  @override
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return AuthResult.failure('Authentication failed. Please try again.');
      }

      // Fetch user profile from RTDB
      final user = await _buildUserFromFirebase(fbUser);
      if (user == null) {
        // User exists in Auth but not in RTDB — orphaned account
        return AuthResult.failure(
          'User profile not found. Please contact support.',
        );
      }

      // Validate expected role (super admin can bypass)
      if (expectedRole != null &&
          user.role != UserRole.superAdmin &&
          user.role != expectedRole) {
        await _firebaseAuth.signOut();
        return AuthResult.failure(
          'This account is not registered as ${expectedRole.displayName}',
        );
      }

      // Check account status
      if (!user.isActive) {
        await _firebaseAuth.signOut();
        return AuthResult.failure('This account has been deactivated.');
      }

      // Check email verification
      if (!fbUser.emailVerified) {
        return AuthResult.notVerified(email);
      }

      // Check approval for roles that require it
      if (user.role.requiresApproval && !user.isApproved) {
        return AuthResult.pendingApproval(user);
      }

      // Update last login timestamp
      await _usersRef.child(fbUser.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      // Get ID token
      final token = await fbUser.getIdToken();

      return AuthResult.success(
        user: user.copyWith(lastLoginAt: DateTime.now()),
        accessToken: token ?? '',
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  @override
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required UserRole role,
    String? municipalityId,
    String? municipalityName,
    String? hospitalId,
    String? hospitalName,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return AuthResult.failure('Account creation failed. Please try again.');
      }

      // Update display name in Firebase Auth
      await fbUser.updateDisplayName('$firstName $lastName');

      // Create user profile in RTDB
      final newUser = User(
        id: fbUser.uid,
        email: email.trim().toLowerCase(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        municipalityId: municipalityId,
        municipalityName: municipalityName,
        hospitalId: hospitalId,
        hospitalName: hospitalName,
        isVerified: false,
        isActive: true,
        isApproved: !role.requiresApproval, // Citizens auto-approved
        createdAt: DateTime.now(),
      );

      await _usersRef.child(fbUser.uid).set(newUser.toJson());

      // Send email verification
      await fbUser.sendEmailVerification();

      // Return appropriate result
      return AuthResult.notVerified(email);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // PASSWORD RESET
  // ===========================================================================

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      return true;
    } catch (_) {
      // Don't reveal whether the email exists for security
      return true;
    }
  }

  // ===========================================================================
  // EMAIL VERIFICATION
  // ===========================================================================

  @override
  Future<bool> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;
      await user.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> reloadEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;
      await user.reload();
      final reloadedUser = _firebaseAuth.currentUser;
      if (reloadedUser != null && reloadedUser.emailVerified) {
        // Update RTDB verification status
        await _usersRef.child(reloadedUser.uid).update({
          'isVerified': true,
        });
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ===========================================================================
  // USER PROFILE OPERATIONS
  // ===========================================================================

  @override
  Future<User?> getUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = uid;
      return User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _usersRef.child(uid).update(updates);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    // Remove profile from RTDB
    await _usersRef.child(user.uid).remove();

    // Delete Firebase Auth account
    await user.delete();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Build a [User] domain model from a Firebase Auth user + RTDB profile.
  Future<User?> _buildUserFromFirebase(fb.User fbUser) async {
    try {
      final snapshot = await _usersRef.child(fbUser.uid).get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = fbUser.uid;
      data['isVerified'] = fbUser.emailVerified;
      return User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Map Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
