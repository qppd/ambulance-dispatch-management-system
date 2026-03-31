import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'system_config_service.dart';

// =============================================================================
// IDLE TIMER SERVICE
// =============================================================================

final idleTimerServiceProvider = Provider<IdleTimerService>((ref) {
  final configAsync = ref.watch(systemConfigProvider);
  final timeoutMinutes = configAsync.valueOrNull?.sessionTimeoutMinutes ?? 60;
  return IdleTimerService(
    timeoutDuration: Duration(minutes: timeoutMinutes),
    onTimeout: () {
      ref.read(authStateProvider.notifier).logout();
    },
  );
});

class IdleTimerService with WidgetsBindingObserver {
  final Duration timeoutDuration;
  final VoidCallback onTimeout;
  Timer? _timer;

  IdleTimerService({
    required this.timeoutDuration,
    required this.onTimeout,
  });

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeoutDuration, onTimeout);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void handleUserInteraction() {
    resetTimer();
  }

  void dispose() {
    stopTimer();
  }
}
