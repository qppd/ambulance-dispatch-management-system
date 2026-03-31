import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Firebase Analytics service provider.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// FirebaseAnalyticsObserver for GoRouter navigation tracking.
final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return service.observer;
});

// =============================================================================
// ANALYTICS SERVICE
// =============================================================================

/// Service for tracking user actions and system events via Firebase Analytics.
///
/// Events follow a consistent naming convention:
/// - `auth_*` — Authentication events
/// - `incident_*` — Incident lifecycle events
/// - `dispatch_*` — Dispatch workflow events
/// - `unit_*` — Unit management events
/// - `nav_*` — Navigation events
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Navigation observer for GoRouter.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ===========================================================================
  // USER PROPERTIES
  // ===========================================================================

  /// Set the current user's identity and properties for analytics.
  Future<void> setUser(User user) async {
    await _analytics.setUserId(id: user.id);
    await _analytics.setUserProperty(name: 'role', value: user.role.name);
    if (user.municipalityId != null) {
      await _analytics.setUserProperty(
        name: 'municipality_id',
        value: user.municipalityId!,
      );
    }
  }

  /// Clear user identity on logout.
  Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
  }

  // ===========================================================================
  // AUTHENTICATION EVENTS
  // ===========================================================================

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'auth_logout');
  }

  Future<void> logPasswordReset() async {
    await _analytics.logEvent(name: 'auth_password_reset');
  }

  // ===========================================================================
  // INCIDENT EVENTS
  // ===========================================================================

  Future<void> logIncidentCreated({
    required String incidentId,
    required String severity,
    required String incidentType,
  }) async {
    await _analytics.logEvent(
      name: 'incident_created',
      parameters: {
        'incident_id': incidentId,
        'severity': severity,
        'incident_type': incidentType,
      },
    );
  }

  Future<void> logIncidentStatusChange({
    required String incidentId,
    required String oldStatus,
    required String newStatus,
  }) async {
    await _analytics.logEvent(
      name: 'incident_status_change',
      parameters: {
        'incident_id': incidentId,
        'old_status': oldStatus,
        'new_status': newStatus,
      },
    );
  }

  Future<void> logIncidentResolved({
    required String incidentId,
    required double totalMinutes,
  }) async {
    await _analytics.logEvent(
      name: 'incident_resolved',
      parameters: {
        'incident_id': incidentId,
        'total_minutes': totalMinutes,
      },
    );
  }

  // ===========================================================================
  // DISPATCH EVENTS
  // ===========================================================================

  Future<void> logDispatch({
    required String incidentId,
    required String unitId,
  }) async {
    await _analytics.logEvent(
      name: 'dispatch_unit',
      parameters: {
        'incident_id': incidentId,
        'unit_id': unitId,
      },
    );
  }

  // ===========================================================================
  // UNIT EVENTS
  // ===========================================================================

  Future<void> logUnitStatusChange({
    required String unitId,
    required String status,
  }) async {
    await _analytics.logEvent(
      name: 'unit_status_change',
      parameters: {
        'unit_id': unitId,
        'status': status,
      },
    );
  }

  // ===========================================================================
  // NAVIGATION EVENTS
  // ===========================================================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ===========================================================================
  // GENERIC EVENT
  // ===========================================================================

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
