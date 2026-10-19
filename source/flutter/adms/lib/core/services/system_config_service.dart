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
    NotifierProvider<SystemConfigNotifier, AsyncValue<SystemConfig>>(
      SystemConfigNotifier.new,
    );

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

/// Notifier that holds the in-progress edits to SystemConfig and
/// calls [SystemConfigService.saveSystemConfig] when the user taps "Save".
class SystemConfigNotifier extends Notifier<AsyncValue<SystemConfig>> {
  @override
  AsyncValue<SystemConfig> build() {
    _load();
    return const AsyncValue.loading();
  }

  /// Seed the working copy from the persisted config.
  ///
  /// This deliberately uses a one-shot [SystemConfigService.fetchSystemConfig]
  /// rather than `ref.listen(systemConfigProvider, ...)`: in Riverpod 3.x a
  /// listener registered inside `Notifier.build()` never fires (the build-time
  /// subscription is torn down before the upstream provider emits), which left
  /// this notifier stuck in [AsyncValue.loading] forever and the settings
  /// screen permanently blank. The old listen callback only ever accepted the
  /// *first* upstream value anyway, so a single fetch is semantically
  /// identical — and later remote changes don't clobber in-progress edits.
  Future<void> _load() async {
    try {
      final config = await ref
          .read(systemConfigServiceProvider)
          .fetchSystemConfig();
      // Only seed if the user hasn't already started editing (toggleBool/
      // updateInt may have run... they no-op while loading, but save() can
      // land first in principle) — never clobber local edits with the fetch.
      if (state is AsyncLoading) {
        state = AsyncData(config);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Called when the user toggles a boolean setting.
  void toggleBool(
    bool Function(SystemConfig c) getter,
    SystemConfig Function(SystemConfig c, bool v) updater,
  ) {
    final current = state.value;
    if (current == null) return;
    final newValue = !getter(current);
    state = AsyncData(updater(current, newValue));
  }

  /// Called when the user updates an integer setting.
  void updateInt(
    SystemConfig Function(SystemConfig c, int v) updater,
    int value,
  ) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(updater(current, value));
  }

  /// Called when the user edits a text setting (e.g. Semaphore SMS API key).
  void updateText(
    SystemConfig Function(SystemConfig c, String v) updater,
    String value,
  ) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(updater(current, value));
  }

  /// Persist current in-memory state to Firebase.
  Future<void> save(String updatedByUid) async {
    final cfg = state.value;
    if (cfg == null) return;
    state = const AsyncValue.loading();
    try {
      final toSave = cfg.copyWith(
        updatedAt: DateTime.now(),
        updatedByUid: updatedByUid,
      );
      await ref.read(systemConfigServiceProvider).saveSystemConfig(toSave);
      state = AsyncData(toSave);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
