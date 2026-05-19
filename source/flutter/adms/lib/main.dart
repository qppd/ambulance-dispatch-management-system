import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/router/router.dart';
import 'core/services/services.dart';
import 'core/models/models.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv. `isOptional: true` ensures it is still initialized
  // even when no .env asset is present.
  await dotenv.load(fileName: '.env', isOptional: true);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence for Firebase RTDB (not supported on web)
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
  }

  runApp(
    const ProviderScope(
      child: AdmsApp(),
    ),
  );
}

/// Main ADMS Application
class AdmsApp extends ConsumerStatefulWidget {
  const AdmsApp({super.key});

  @override
  ConsumerState<AdmsApp> createState() => _AdmsAppState();
}

class _AdmsAppState extends ConsumerState<AdmsApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    } catch (e) {
      // FCM may not be available on all platforms
      debugPrint('Notification init error (non-fatal): $e');
    }
  }

  void _saveFcmToken(User user) {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final token = notificationService.currentToken;
      if (token != null) {
        ref.read(userServiceProvider).saveFcmToken(user.id, token);
      }
      notificationService.onTokenRefresh((newToken) {
        ref.read(userServiceProvider).saveFcmToken(user.id, newToken);
      });
      notificationService.subscribeForUser(user);
    } catch (e) {
      // Graceful degradation if FCM unavailable
      debugPrint('FCM token save error (non-fatal): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final authState = ref.watch(authStateProvider);

    // Save FCM token when authenticated
    if (authState is AuthAuthenticated) {
      _saveFcmToken(authState.user);
    }

    // Start idle timer when authenticated
    if (authState is AuthAuthenticated) {
      ref.read(idleTimerServiceProvider).resetTimer();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (authState is AuthAuthenticated) {
          ref.read(idleTimerServiceProvider).handleUserInteraction();
        }
      },
      onPanDown: (_) {
        if (authState is AuthAuthenticated) {
          ref.read(idleTimerServiceProvider).handleUserInteraction();
        }
      },
      child: MaterialApp.router(
        title: 'ADMS - Ambulance Dispatch Management System',
        debugShowCheckedModeBanner: kDebugMode,

        // Theme configuration
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,

        // Router configuration
        routerConfig: router,

        builder: (context, child) {
          return Column(
            children: [
              // Offline banner
              isOnline.when(
                data: (online) => online
                    ? const SizedBox.shrink()
                    : MaterialBanner(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        content: const Row(
                          children: [
                            Icon(Icons.cloud_off, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('You are offline. Changes will sync when reconnected.',
                                style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                        backgroundColor: Colors.red.shade700,
                        actions: [SizedBox.shrink()],
                      ),
                loading: () => const SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(minHeight: 4),
                ),
                error: (e, __) => MaterialBanner(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  content: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Connection check failed',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade700,
                  actions: [SizedBox.shrink()],
                ),
              ),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}
