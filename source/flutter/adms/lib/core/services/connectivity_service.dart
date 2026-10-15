import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Connectivity service provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream of connectivity status changes.
///
/// Seeded with an explicit `checkConnectivity()` before streaming updates:
/// on web, `connectivity_plus`'s `onConnectivityChanged` is a broadcast stream
/// fed only by the browser's `online`/`offline` events, so it never emits on
/// subscribe. Left unseeded this provider (and `isOnlineProvider` below) sits
/// in its loading state indefinitely whenever the initial status is unchanged.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkConnectivity();
  yield* service.watchConnectivity();
});

/// Whether the device currently has network connectivity.
///
/// The initial `yield` is load-bearing, not an optimisation: without it a
/// `StreamProvider` never leaves `AsyncLoading` on web (see
/// [connectivityStreamProvider]), and the offline banner in `main.dart` would
/// render an indeterminate progress bar across the top of the page forever.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isConnected();
  yield* service.watchConnectivity().map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

// =============================================================================
// CONNECTIVITY SERVICE
// =============================================================================

/// Service for monitoring network connectivity and managing offline behaviour.
///
/// Uses `connectivity_plus` to detect network changes and configures
/// Firebase RTDB disk persistence so queued writes survive app restarts.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Enable Firebase RTDB offline persistence.
  ///
  /// Call once during app startup. Queued writes are persisted to disk
  /// and automatically sent when the device reconnects.
  Future<void> enableOfflinePersistence() async {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
  }

  /// Manually trigger a Firebase RTDB connectivity check.
  Future<void> goOnline() async {
    FirebaseDatabase.instance.goOnline();
  }

  /// Manually pause Firebase RTDB sync (battery saving).
  Future<void> goOffline() async {
    FirebaseDatabase.instance.goOffline();
  }

  // ===========================================================================
  // CONNECTIVITY MONITORING
  // ===========================================================================

  /// Check current connectivity status.
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Check current connectivity status, returning the raw platform results.
  ///
  /// Needed to seed the connectivity providers: `onConnectivityChanged` does
  /// not emit an initial value on web, so an explicit check is required.
  Future<List<ConnectivityResult>> checkConnectivity() {
    return _connectivity.checkConnectivity();
  }

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> watchConnectivity() {
    return _connectivity.onConnectivityChanged;
  }

  /// Get a human-readable description of the current connection type.
  static String describeConnection(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return 'Offline';
    if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (results.contains(ConnectivityResult.mobile)) return 'Mobile Data';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Connected';
  }
}
