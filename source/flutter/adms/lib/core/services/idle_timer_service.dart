import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'system_config_service.dart';

// =============================================================================
// IDLE TIMER SERVICE
// =============================================================================

/// Session-timeout controller.
///
/// The provider watches BOTH the auth state and the system config:
/// - a fresh service (with a freshly started timer) is created whenever a user
///   signs in or the Super Admin changes the session-timeout setting, and the
///   old timer is disposed;
/// - the timer only runs while a user is actually authenticated.
///
/// Because the service itself is wired to the auth lifecycle, the timeout
/// applies to EVERY role (citizen, driver, municipal admin and super admin)
/// — previously the timer was restarted on every widget rebuild, so any
/// frequently rebuilding screen kept it alive forever and nobody was ever
/// logged out.
final idleTimerServiceProvider = Provider<IdleTimerService>((ref) {
  final authState = ref.watch(authStateProvider);
  final configAsync = ref.watch(systemConfigProvider);
  final timeoutMinutes = configAsync.value?.sessionTimeoutMinutes ?? 60;

  final service = IdleTimerService(
    timeoutDuration: Duration(minutes: timeoutMinutes),
    onTimeout: () {
      // Only sign out if someone is still signed in when the timer fires.
      if (ref.read(authStateProvider) is AuthAuthenticated) {
        ref
            .read(authStateProvider.notifier)
            .logout(
              message:
                  'Session timed out due to inactivity. Please sign in again.',
            );
      }
    },
  );

  // Start counting down immediately for the currently signed-in user.
  if (authState is AuthAuthenticated) {
    service.resetTimer();
  }

  // Tear the timer down whenever the provider is rebuilt (login, logout,
  // role change, timeout reconfiguration) so no orphan timer can fire.
  ref.onDispose(service.dispose);

  return service;
});

class IdleTimerService with WidgetsBindingObserver {
  final Duration timeoutDuration;
  final VoidCallback onTimeout;
  Timer? _timer;

  IdleTimerService({required this.timeoutDuration, required this.onTimeout});

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeoutDuration, onTimeout);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Called from the root interaction listener on any pointer input.
  void handleUserInteraction() {
    if (_timer == null) return; // Not authenticated — nothing to reset.
    resetTimer();
  }

  void dispose() {
    stopTimer();
  }
}
