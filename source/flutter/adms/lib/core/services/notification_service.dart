import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// FCM notification service provider.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Stream of foreground FCM messages.
final foregroundMessagesProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});

// =============================================================================
// NOTIFICATION SERVICE
// =============================================================================

/// Service for managing Firebase Cloud Messaging notifications.
///
/// Topic-based subscription model:
/// - `municipality_{municipalityId}` — All alerts for a municipality
/// - `municipality_{municipalityId}_dispatchers` — Dispatcher-specific
/// - `municipality_{municipalityId}_drivers` — Driver-specific
/// - `municipality_{municipalityId}_hospital_{hospitalId}` — Hospital-specific
/// - `incident_{municipalityId}_{incidentId}` — Incident updates
/// - `global_announcements` — System-wide announcements
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize FCM and request permissions.
  Future<void> initialize() async {
    // Request notification permissions (iOS/macOS/web)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // Emergency system needs critical alerts
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Get FCM token for this device
    final token = await _messaging.getToken();
    if (token != null) {
      // Store token in RTDB (associated with user) for direct messaging
      _currentToken = token;
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _onTokenRefreshCallback?.call(newToken);
    });
  }

  String? _currentToken;
  void Function(String)? _onTokenRefreshCallback;

  /// Get the current FCM token.
  String? get currentToken => _currentToken;

  /// Set callback for token refresh events (to update RTDB).
  void onTokenRefresh(void Function(String) callback) {
    _onTokenRefreshCallback = callback;
  }

  // ===========================================================================
  // TOPIC SUBSCRIPTIONS
  // ===========================================================================

  /// Subscribe to topics based on user role and municipality.
  Future<void> subscribeForUser(User user) async {
    // All users in a municipality get general alerts
    if (user.municipalityId != null) {
      await _messaging.subscribeToTopic(
        'municipality_${user.municipalityId}',
      );
    }

    // Role-specific topics
    switch (user.role) {
      case UserRole.dispatcher:
        if (user.municipalityId != null) {
          await _messaging.subscribeToTopic(
            'municipality_${user.municipalityId}_dispatchers',
          );
        }
        break;
      case UserRole.driver:
        if (user.municipalityId != null) {
          await _messaging.subscribeToTopic(
            'municipality_${user.municipalityId}_drivers',
          );
        }
        break;
      case UserRole.hospitalStaff:
        if (user.municipalityId != null && user.hospitalId != null) {
          await _messaging.subscribeToTopic(
            'municipality_${user.municipalityId}_hospital_${user.hospitalId}',
          );
        }
        break;
      case UserRole.superAdmin:
        await _messaging.subscribeToTopic('global_announcements');
        break;
      case UserRole.municipalAdmin:
        if (user.municipalityId != null) {
          await _messaging.subscribeToTopic(
            'municipality_${user.municipalityId}_admin',
          );
        }
        await _messaging.subscribeToTopic('global_announcements');
        break;
      case UserRole.citizen:
        // Citizens only get subscribed to specific incident topics
        break;
    }
  }

  /// Unsubscribe from all topics (call on logout).
  Future<void> unsubscribeAll(User user) async {
    if (user.municipalityId != null) {
      await _messaging.unsubscribeFromTopic(
        'municipality_${user.municipalityId}',
      );
      await _messaging.unsubscribeFromTopic(
        'municipality_${user.municipalityId}_dispatchers',
      );
      await _messaging.unsubscribeFromTopic(
        'municipality_${user.municipalityId}_drivers',
      );
      if (user.hospitalId != null) {
        await _messaging.unsubscribeFromTopic(
          'municipality_${user.municipalityId}_hospital_${user.hospitalId}',
        );
      }
      await _messaging.unsubscribeFromTopic(
        'municipality_${user.municipalityId}_admin',
      );
    }
    await _messaging.unsubscribeFromTopic('global_announcements');
  }

  /// Subscribe to updates for a specific incident (citizen tracking).
  Future<void> subscribeToIncident(
    String municipalityId,
    String incidentId,
  ) async {
    await _messaging.subscribeToTopic(
      'incident_${municipalityId}_$incidentId',
    );
  }

  /// Unsubscribe from a specific incident's updates.
  Future<void> unsubscribeFromIncident(
    String municipalityId,
    String incidentId,
  ) async {
    await _messaging.unsubscribeFromTopic(
      'incident_${municipalityId}_$incidentId',
    );
  }

  // ===========================================================================
  // NOTIFICATION PARSING
  // ===========================================================================

  /// Parse an FCM message into a structured notification.
  static NotificationPayload parseMessage(RemoteMessage message) {
    final data = message.data;
    return NotificationPayload(
      type: data['type'] ?? 'general',
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      municipalityId: data['municipalityId'],
      incidentId: data['incidentId'],
      unitId: data['unitId'],
      severity: data['severity'],
      extra: data,
    );
  }
}

/// Structured notification data extracted from FCM message.
class NotificationPayload {
  final String type;
  final String title;
  final String body;
  final String? municipalityId;
  final String? incidentId;
  final String? unitId;
  final String? severity;
  final Map<String, dynamic> extra;

  const NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    this.municipalityId,
    this.incidentId,
    this.unitId,
    this.severity,
    this.extra = const {},
  });

  /// Common notification types
  static const String typeNewIncident = 'new_incident';
  static const String typeIncidentUpdate = 'incident_update';
  static const String typeDispatch = 'dispatch';
  static const String typeUnitArrival = 'unit_arrival';
  static const String typeHospitalAlert = 'hospital_alert';
  static const String typeAnnouncement = 'announcement';
}
