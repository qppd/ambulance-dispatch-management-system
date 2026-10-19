import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
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
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

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
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepo;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DatabaseEvent>? _profileSubscription;

  @override
  AuthState build() {
    _authRepo = ref.watch(authRepositoryProvider);

    // Set initial state to loading while we check auth
    _listenToAuthChanges();
    ref.onDispose(() {
      _authSubscription?.cancel();
      _profileSubscription?.cancel();
    });
    return const AuthInitial();
  }

  /// Watch the signed-in user's own `/users/{uid}` record in realtime so a
  /// deactivation by an administrator logs the account out immediately —
  /// not only at the next login / token refresh. RTDB rules allow a user to
  /// read their own record, and the listener is torn down on sign-out.
  void _watchOwnProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = FirebaseDatabase.instance
        .ref('users/$uid')
        .onValue
        .listen((event) {
          final value = event.snapshot.value;
          if (value is! Map) return;
          final map = Map<String, dynamic>.from(value);
          if (map['isActive'] == false && state is AuthAuthenticated) {
            // Fire-and-forget: sign out and surface why.
            logout(message: 'Your account has been deactivated.');
          }
        });
  }

  void _stopWatchingOwnProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  /// Listen to Firebase Auth state changes for automatic state updates.
  void _listenToAuthChanges() {
    state = const AuthLoading();

    _authSubscription = _authRepo.authStateChanges.listen(
      (user) async {
        if (user == null) {
          // Only transition to unauthenticated if we were previously
          // authenticated or in initial/loading state.
          _stopWatchingOwnProfile();
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
            // Get fresh token — F9 FIX: use repo instead of direct FirebaseAuth.instance
            final uid = _authRepo.currentUid;
            if (uid == null) {
              state = const AuthError(
                message: 'Session expired. Please sign in again.',
              );
              return;
            }
            final user = await _authRepo.getUserProfile(uid);
            if (user == null) {
              state = const AuthError(message: 'User profile not found.');
              return;
            }

            // Deactivated-municipality gate (staff roles): when a municipality
            // is deactivated by the Super Admin, its municipal admins and
            // drivers may no longer perform any operation. Block them at the
            // auth layer so no screen is reachable. Citizens keep read access
            // to their own data — the request flow itself refuses to file
            // ambulance requests for a deactivated municipality.
            final blocked = await _postSignInGate(user);
            if (blocked != null) {
              state = blocked;
              return;
            }

            final token =
                ''; // Token is obtained during login; for re-auth, user will re-login
            state = AuthAuthenticated(user: user, accessToken: token);
            // Enforce mid-session deactivation: log out the moment an
            // administrator flips this account's isActive to false.
            _watchOwnProfile(uid);
          }
        }
      },
      onError: (error) {
        state = AuthError(message: 'Authentication error: $error');
      },
    );
  }

  /// Whether the municipality is currently active.
  ///
  /// Returns `null` when the status cannot be determined (offline, rules
  /// denial, unknown id) so a transient read failure never locks staff out.
  Future<bool?> _isMunicipalityActive(String municipalityId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('municipalities/$municipalityId/isActive')
          .get();
      if (!snapshot.exists) return null;
      return snapshot.value as bool?;
    } catch (_) {
      return null;
    }
  }

  /// Post-sign-in gates that must hold before an account is let in.
  ///
  /// Returns the terminal [AuthState] to adopt when the sign-in must be
  /// refused, or `null` when the account may proceed.
  ///
  /// This is deliberately shared by the realtime auth listener AND [login]:
  /// both run against the same sign-in event, and if only one of them applied
  /// the gate the two writes raced — the loser silently overwrote the other.
  /// That race is what made a deactivated municipality bounce the admin back
  /// to the login screen with no message.
  Future<AuthState?> _postSignInGate(User user) async {
    if (user.role != UserRole.municipalAdmin &&
        user.role != UserRole.driver) {
      return null;
    }
    final municipalityId = user.municipalityId;
    if (municipalityId == null || municipalityId.isEmpty) return null;

    final isActive = await _isMunicipalityActive(municipalityId);
    if (isActive != false) return null;

    await _authRepo.signOut();
    return const AuthError(
      message:
          'Your municipality has been deactivated. '
          'Please contact the Super Administrator.',
    );
  }

  /// Sign in with email and password.
  ///
  /// The account's own role is not validated here; the router redirects each
  /// account to the dashboard matching that role once sign-in succeeds.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await _authRepo.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // The realtime auth listener processes this same sign-in concurrently. If
    // it already refused the account (unverified, unapproved, deactivated
    // account or deactivated municipality), its message is authoritative.
    // Overwriting it here with `result` used to resurrect a stale "success",
    // which the sign-out that followed then downgraded to a message-less
    // AuthUnauthenticated — the admin was silently bounced back to login.
    final resolved = state;
    if (resolved is AuthError ||
        resolved is AuthPendingApproval ||
        resolved is AuthNotVerified) {
      return;
    }

    if (result.isSuccess && result.user != null) {
      final blocked = await _postSignInGate(result.user!);
      if (blocked != null) {
        state = blocked;
        return;
      }
    }

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
      // Re-trigger auth stream to update state — F9 FIX: use repo instead of direct FirebaseAuth.instance
      final uid = _authRepo.currentUid;
      if (uid != null) {
        final user = await _authRepo.getUserProfile(uid);
        if (user != null) {
          if (user.role.requiresApproval && !user.isApproved) {
            state = AuthPendingApproval(user: user);
          } else {
            state = AuthAuthenticated(user: user, accessToken: '');
          }
        }
      }
    }
    return verified;
  }

  /// Sign out.
  ///
  /// [message] lets callers explain why the user was signed out (e.g. the
  /// session-timeout message from [IdleTimerService]).
  Future<void> logout({String message = 'You have been logged out'}) async {
    state = const AuthLoading();
    _stopWatchingOwnProfile();
    await _authRepo.signOut();
    state = AuthUnauthenticated(message: message);
  }

  /// Clear error state.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
