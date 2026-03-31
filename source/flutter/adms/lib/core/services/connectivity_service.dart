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
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.watchConnectivity();
});

/// Whether the device currently has network connectivity.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.watchConnectivity().map(
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
