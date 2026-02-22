import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/repositories.dart';
import '../models/models.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Auth repository provider — single source of truth for auth operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Firebase auth state stream provider.
/// Listens to Firebase Auth state changes and maps to app User.
final firebaseAuthStreamProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Auth state provider — manages the application authentication state.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});

/// Current user provider (convenience accessor).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

// =============================================================================
// AUTH NOTIFIER
// =============================================================================

/// Auth state notifier using Firebase Authentication + RTDB.
///
/// Listens to Firebase authStateChanges to automatically update state
/// when the user signs in/out externally (e.g., token expiry).
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authRepo) : super(const AuthInitial()) {
    _listenToAuthChanges();
  }

  /// Listen to Firebase Auth state changes for automatic state updates.
  void _listenToAuthChanges() {
    state = const AuthLoading();

    _authSubscription = _authRepo.authStateChanges.listen(
      (user) async {
        if (user == null) {
          // Only transition to unauthenticated if we were previously
          // authenticated or in initial/loading state.
          if (state is AuthAuthenticated ||
              state is AuthInitial ||
              state is AuthLoading) {
            state = const AuthUnauthenticated();
          }
        } else {
          // Check various user statuses
          if (!user.isVerified) {
            state = AuthNotVerified(email: user.email);
          } else if (user.role.requiresApproval && !user.isApproved) {
            state = AuthPendingApproval(user: user);
          } else if (!user.isActive) {
            await _authRepo.signOut();
            state = const AuthError(
              message: 'This account has been deactivated.',
            );
          } else {
            // Get fresh token
            final fbUser = fb.FirebaseAuth.instance.currentUser;
            final token = await fbUser?.getIdToken() ?? '';
            state = AuthAuthenticated(
              user: user,
              accessToken: token,
            );
          }
        }
      },
      onError: (error) {
        state = AuthError(message: 'Authentication error: $error');
      },
    );
  }

  /// Sign in with email and password.
  Future<void> login({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    state = const AuthLoading();

    final result = await _authRepo.signInWithEmailAndPassword(
      email: email,
      password: password,
      expectedRole: expectedRole,
    );

    state = result.toAuthState();
  }

  /// Register a new account.
  Future<void> register({
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
    state = const AuthLoading();

    final result = await _authRepo.registerWithEmailAndPassword(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role,
      municipalityId: municipalityId,
      municipalityName: municipalityName,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
    );

    state = result.toAuthState();
  }

  /// Send password reset email.
  Future<bool> sendPasswordReset(String email) async {
    return _authRepo.sendPasswordResetEmail(email);
  }

  /// Send email verification to current user.
  Future<bool> sendEmailVerification() async {
    return _authRepo.sendEmailVerification();
  }

  /// Check if email has been verified.
  Future<bool> checkEmailVerification() async {
    final verified = await _authRepo.reloadEmailVerification();
    if (verified) {
      // Re-trigger auth stream to update state
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final user = await _authRepo.getUserProfile(fbUser.uid);
        if (user != null) {
          final token = await fbUser.getIdToken() ?? '';
          if (user.role.requiresApproval && !user.isApproved) {
            state = AuthPendingApproval(user: user);
          } else {
            state = AuthAuthenticated(user: user, accessToken: token);
          }
        }
      }
    }
    return verified;
  }

  /// Sign out.
  Future<void> logout() async {
    state = const AuthLoading();
    await _authRepo.signOut();
    state = const AuthUnauthenticated(message: 'You have been logged out');
  }

  /// Clear error state.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

