import 'package:equatable/equatable.dart';

// =============================================================================
// SYSTEM CONFIG MODEL
// =============================================================================

/// System-wide configuration stored at /systemConfig in Firebase RTDB.
///
/// Super Admins can read and write this node. All other roles have
/// read-only access to relevant settings (e.g. responseTimeThreshold).
class SystemConfig extends Equatable {
  // ── Notifications ──────────────────────────────────────────────────────────
  /// Whether FCM push notifications are globally enabled.
  final bool pushNotificationsEnabled;

  /// Whether SMS alerts are globally enabled.
  final bool smsAlertsEnabled;

  // ── Dispatch ───────────────────────────────────────────────────────────────
  /// Whether the system should automatically assign the nearest available unit.
  final bool autoDispatchEnabled;

  /// Incidents with a response time exceeding this value (in minutes) are
  /// flagged for review.
  final int responseTimeThresholdMinutes;

  // ── Security ───────────────────────────────────────────────────────────────
  /// Whether newly registered accounts require Super Admin approval before
  /// they can log in.
  final bool requireAdminApproval;

  /// Idle session duration (in minutes) before the user is automatically
  /// signed out.
  final int sessionTimeoutMinutes;

  // ── Metadata ───────────────────────────────────────────────────────────────
  /// Timestamp of the last update.
  final DateTime? updatedAt;

  /// UID of the Super Admin who made the last update.
  final String? updatedByUid;

  const SystemConfig({
    this.pushNotificationsEnabled = true,
    this.smsAlertsEnabled = false,
    this.autoDispatchEnabled = false,
    this.responseTimeThresholdMinutes = 10,
    this.requireAdminApproval = true,
    this.sessionTimeoutMinutes = 60,
    this.updatedAt,
    this.updatedByUid,
  });

  /// Default / fallback configuration used before the RTDB value is loaded.
  factory SystemConfig.defaults() => const SystemConfig();

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'pushNotificationsEnabled': pushNotificationsEnabled,
        'smsAlertsEnabled': smsAlertsEnabled,
        'autoDispatchEnabled': autoDispatchEnabled,
        'responseTimeThresholdMinutes': responseTimeThresholdMinutes,
        'requireAdminApproval': requireAdminApproval,
        'sessionTimeoutMinutes': sessionTimeoutMinutes,
        'updatedAt': updatedAt?.toIso8601String(),
        'updatedByUid': updatedByUid,
      };

  factory SystemConfig.fromJson(Map<dynamic, dynamic> json) => SystemConfig(
        pushNotificationsEnabled:
            json['pushNotificationsEnabled'] as bool? ?? true,
        smsAlertsEnabled: json['smsAlertsEnabled'] as bool? ?? false,
        autoDispatchEnabled: json['autoDispatchEnabled'] as bool? ?? false,
        responseTimeThresholdMinutes:
            (json['responseTimeThresholdMinutes'] as num?)?.toInt() ?? 10,
        requireAdminApproval: json['requireAdminApproval'] as bool? ?? true,
        sessionTimeoutMinutes:
            (json['sessionTimeoutMinutes'] as num?)?.toInt() ?? 60,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        updatedByUid: json['updatedByUid'] as String?,
      );

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  SystemConfig copyWith({
    bool? pushNotificationsEnabled,
    bool? smsAlertsEnabled,
    bool? autoDispatchEnabled,
    int? responseTimeThresholdMinutes,
    bool? requireAdminApproval,
    int? sessionTimeoutMinutes,
    DateTime? updatedAt,
    String? updatedByUid,
  }) =>
      SystemConfig(
        pushNotificationsEnabled:
            pushNotificationsEnabled ?? this.pushNotificationsEnabled,
        smsAlertsEnabled: smsAlertsEnabled ?? this.smsAlertsEnabled,
        autoDispatchEnabled: autoDispatchEnabled ?? this.autoDispatchEnabled,
        responseTimeThresholdMinutes:
            responseTimeThresholdMinutes ?? this.responseTimeThresholdMinutes,
        requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
        sessionTimeoutMinutes:
            sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedByUid: updatedByUid ?? this.updatedByUid,
      );

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        smsAlertsEnabled,
        autoDispatchEnabled,
        responseTimeThresholdMinutes,
        requireAdminApproval,
        sessionTimeoutMinutes,
        updatedAt,
        updatedByUid,
      ];
}
