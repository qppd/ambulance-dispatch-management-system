import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/services/connectivity_service.dart';

/// Mimics `connectivity_plus` 7.x on the web.
///
/// The web implementation exposes the current status via `checkConnectivity()`
/// (`navigator.onLine`), but `onConnectivityChanged` is a broadcast stream fed
/// only by the browser's `online`/`offline` DOM events. A user who opens the
/// app already online therefore never receives a single event — which is
/// exactly the condition that left the top-of-page progress bar spinning.
class _WebLikeConnectivityService implements ConnectivityService {
  _WebLikeConnectivityService(this._current);

  final List<ConnectivityResult> _current;

  final StreamController<List<ConnectivityResult>> _changes =
      StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<bool> isConnected() async =>
      !_current.contains(ConnectivityResult.none);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _current;

  @override
  Stream<List<ConnectivityResult>> watchConnectivity() => _changes.stream;

  @override
  Future<void> enableOfflinePersistence() async {}

  @override
  Future<void> goOnline() async {}

  @override
  Future<void> goOffline() async {}

  void dispose() => _changes.close();
}

/// Starts the provider and returns the container.
///
/// Riverpod only runs a `StreamProvider` body once it has a listener, so a
/// bare `read` would leave it uninitialised and every assertion below would
/// pass vacuously.
({ProviderContainer container, void Function() dispose}) _start(
  _WebLikeConnectivityService service,
) {
  final container = ProviderContainer(
    overrides: [connectivityServiceProvider.overrideWithValue(service)],
  );
  final sub = container.listen(isOnlineProvider, (prev, next) {});
  return (
    container: container,
    dispose: () {
      sub.close();
      container.dispose();
      service.dispose();
    },
  );
}

void main() {
  test(
    'isOnlineProvider resolves with no connectivity change ever firing',
    () async {
      final s = _start(_WebLikeConnectivityService([ConnectivityResult.wifi]));
      addTearDown(s.dispose);

      // If the provider waited on the change stream this would never complete,
      // so time out with a message naming the visible symptom.
      final online = await s.container
          .read(isOnlineProvider.future)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw StateError(
              'isOnlineProvider never left its loading state: the '
              'top-of-page progress bar would spin forever.',
            ),
          );

      expect(online, isTrue);
      expect(s.container.read(isOnlineProvider).hasValue, isTrue);
    },
  );

  test('isOnlineProvider reports the seeded offline status', () async {
    final s = _start(_WebLikeConnectivityService([ConnectivityResult.none]));
    addTearDown(s.dispose);

    final online = await s.container
        .read(isOnlineProvider.future)
        .timeout(const Duration(seconds: 5));
    expect(online, isFalse);
  });

  test('isOnlineProvider still follows a later connectivity change', () async {
    final service = _WebLikeConnectivityService([ConnectivityResult.wifi]);
    final container = ProviderContainer(
      overrides: [connectivityServiceProvider.overrideWithValue(service)],
    );
    addTearDown(() {
      container.dispose();
      service.dispose();
    });

    final wentOffline = Completer<bool>();
    final sub = container.listen(isOnlineProvider, (previous, next) {
      final value = next.value;
      if (value != null && !value && !wentOffline.isCompleted) {
        wentOffline.complete(value);
      }
    });
    addTearDown(sub.close);

    // Give the seeded value time to arrive before asserting on the change.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      container.read(isOnlineProvider).value,
      isTrue,
      reason: 'seeded online status',
    );

    service._changes.add([ConnectivityResult.none]);

    await wentOffline.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError(
        'A connectivity change after startup was never observed.',
      ),
    );
  });
}
