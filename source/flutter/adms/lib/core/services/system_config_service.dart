import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// System config service provider.
final systemConfigServiceProvider = Provider<SystemConfigService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return SystemConfigService(dbRef);
});

/// Live stream of the system configuration.
final systemConfigProvider = StreamProvider<SystemConfig>((ref) {
  final service = ref.watch(systemConfigServiceProvider);
  return service.watchSystemConfig();
});

/// Notifier that manages in-memory edits to [SystemConfig] before persisting.
final systemConfigNotifierProvider =
    StateNotifierProvider<SystemConfigNotifier, AsyncValue<SystemConfig>>(
        (ref) {
  return SystemConfigNotifier(ref);
});

// =============================================================================
// SYSTEM CONFIG SERVICE
// =============================================================================

/// Service for reading and writing the global system configuration.
///
/// RTDB path: /systemConfig
class SystemConfigService {
  final DatabaseReference _dbRef;

  SystemConfigService(this._dbRef);

  DatabaseReference get _configRef => _dbRef.child('systemConfig');

  // ===========================================================================
  // READ
  // ===========================================================================

  /// Real-time stream of the system configuration.
  Stream<SystemConfig> watchSystemConfig() {
    return _configRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return SystemConfig.defaults();
      return SystemConfig.fromJson(data);
    });
  }

  /// Fetch the system configuration once (non-streaming).
  Future<SystemConfig> fetchSystemConfig() async {
    final snapshot = await _configRef.get();
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return SystemConfig.defaults();
    return SystemConfig.fromJson(data);
  }

  // ===========================================================================
  // WRITE
  // ===========================================================================

  /// Persist the entire config to Firebase RTDB.
  Future<void> saveSystemConfig(SystemConfig config) async {
    await _configRef.set(config.toJson());
  }

  /// Update a single boolean flag without rewriting the whole document.
  Future<void> updateFlag(String key, bool value) async {
    await _configRef.update({key: value});
  }

  /// Update a single integer setting.
  Future<void> updateInt(String key, int value) async {
    await _configRef.update({key: value});
  }
}

// =============================================================================
// SYSTEM CONFIG NOTIFIER
// =============================================================================

/// StateNotifier that holds the in-progress edits to SystemConfig and
/// calls [SystemConfigService.saveSystemConfig] when the user taps "Save".
class SystemConfigNotifier extends StateNotifier<AsyncValue<SystemConfig>> {
  SystemConfigNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  void _load() {
    _ref.listen<AsyncValue<SystemConfig>>(systemConfigProvider, (_, next) {
      if (state is! AsyncData) {
        // Accept the first upstream value as our working copy.
        state = next;
      }
    });
  }

  /// Called when the user toggles a boolean setting.
  void toggleBool(bool Function(SystemConfig c) getter,
      SystemConfig Function(SystemConfig c, bool v) updater) {
    final current = state.valueOrNull;
    if (current == null) return;
    final newValue = !getter(current);
    state = AsyncData(updater(current, newValue));
  }

  /// Called when the user updates an integer setting.
  void updateInt(
      SystemConfig Function(SystemConfig c, int v) updater, int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(updater(current, value));
  }

  /// Persist current in-memory state to Firebase.
  Future<void> save(String updatedByUid) async {
    final cfg = state.valueOrNull;
    if (cfg == null) return;
    state = const AsyncValue.loading();
    try {
      final toSave = cfg.copyWith(
        updatedAt: DateTime.now(),
        updatedByUid: updatedByUid,
      );
      await _ref.read(systemConfigServiceProvider).saveSystemConfig(toSave);
      state = AsyncData(toSave);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
