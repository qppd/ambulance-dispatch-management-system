import '../models/models.dart';

/// Abstract authentication repository interface.
///
/// Defines the contract for all authentication operations.
/// Implementations can use Firebase Auth, mock data, or any other backend.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  /// Emits whenever the user signs in, signs out, or token refreshes.
  Stream<User?> get authStateChanges;

  /// Currently authenticated user, or null if not signed in.
  User? get currentUser;

  /// Sign in with email and password.
  ///
  /// [expectedRole] optionally validates the user's role matches.
  /// Returns [AuthResult] indicating success, failure, pending approval, etc.
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole? expectedRole,
  });

  /// Register a new user account.
  ///
  /// Creates the Firebase Auth account and writes user profile to RTDB.
  /// Returns [AuthResult] with appropriate state (notVerified, pendingApproval, etc.)
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
  });

  /// Send a password reset email to the specified address.
  Future<bool> sendPasswordResetEmail(String email);

  /// Send email verification to the currently signed-in user.
  Future<bool> sendEmailVerification();

  /// Reload the current user's email verification status from Firebase.
  /// Returns true if the email is now verified.
  Future<bool> reloadEmailVerification();

  /// Sign out the current user.
  Future<void> signOut();

  /// Fetch the user profile from RTDB by UID.
  Future<User?> getUserProfile(String uid);

  /// Update user profile fields in RTDB.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates);

  /// Delete the current user's account.
  Future<void> deleteAccount();
}

/// Result of an authentication operation.
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;
  final bool isPendingApproval;
  final bool isNotVerified;
  final String? email;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
    this.isPendingApproval = false,
    this.isNotVerified = false,
    this.email,
  });

  factory AuthResult.success({
    required User user,
    required String accessToken,
    String? refreshToken,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory AuthResult.pendingApproval(User user) {
    return AuthResult._(
      isSuccess: false,
      user: user,
      isPendingApproval: true,
    );
  }

  factory AuthResult.notVerified(String email) {
    return AuthResult._(
      isSuccess: false,
      isNotVerified: true,
      email: email,
    );
  }

  /// Convert to [AuthState] for the state notifier.
  AuthState toAuthState() {
    if (isSuccess && user != null && accessToken != null) {
      return AuthAuthenticated(
        user: user!,
        accessToken: accessToken!,
        refreshToken: refreshToken,
      );
    }

    if (isPendingApproval && user != null) {
      return AuthPendingApproval(user: user!);
    }

    if (isNotVerified && email != null) {
      return AuthNotVerified(email: email!);
    }

    return AuthError(message: errorMessage ?? 'Authentication failed');
  }
}
