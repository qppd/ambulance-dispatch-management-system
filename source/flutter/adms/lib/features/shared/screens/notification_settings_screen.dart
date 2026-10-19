import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Realtime notification preferences for whoever is signed in.
/// Citizens keep them under /citizen/{uid}; every other role under /users/{uid}.
///
/// The screen watches this provider each build, so toggles always reflect the
/// latest stream emission — no initState snapshot, no manual refresh.
///
/// (Note: Riverpod 3 removed the old `provider.stream` getter, so the role
/// dispatch below subscribes to the very same service streams that back
/// [citizenNotificationPrefsProvider] and [userNotificationPrefsProvider].)
final notificationPrefsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream<Map<String, dynamic>>.empty();
  if (user.role == UserRole.citizen) {
    // /citizen/{uid}/notificationPrefs (same stream as citizenNotificationPrefsProvider).
    return ref.watch(citizenServiceProvider).watchNotificationPrefs();
  }
  // /users/{uid}/notificationPrefs (same stream as userNotificationPrefsProvider).
  return ref.watch(userServiceProvider).watchNotificationPrefs(user.id);
});

/// Persists notification toggles to the signed-in user's role-specific path.
///
/// Citizens write through [citizenServiceProvider] (/citizen/{uid}); every
/// other role (driver, admin, ...) writes through [userServiceProvider]
/// (/users/{uid}). The realtime stream then echoes the saved values back and
/// the UI updates on its own.
Future<void> _saveNotificationPrefs(
  WidgetRef ref, {
  required bool incidentUpdates,
  required bool systemAnnouncements,
}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    throw StateError('You must be signed in to save notification preferences.');
  }
  if (user.role == UserRole.citizen) {
    await ref.read(citizenServiceProvider).saveNotificationPrefs(
          incidentUpdates: incidentUpdates,
          systemAnnouncements: systemAnnouncements,
        );
    return;
  }
  await ref.read(userServiceProvider).saveNotificationPrefs(
        uid: user.id,
        incidentUpdates: incidentUpdates,
        systemAnnouncements: systemAnnouncements,
      );
}

/// Which toggle on the screen is being saved (one switch never blocks the other).
enum _PrefKey { incidentUpdates, systemAnnouncements }

/// Screen for managing notification preferences.
/// Accessible from: Profile > Notifications.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// Per-toggle busy flags — a slow write on one switch does not block the other.
  final Map<_PrefKey, bool> _saving = {
    _PrefKey.incidentUpdates: false,
    _PrefKey.systemAnnouncements: false,
  };

  @override
  Widget build(BuildContext context) {
    // Derived from the watched stream every build: updates arrive realtime.
    final prefs = ref.watch(notificationPrefsProvider).value;
    final incidentUpdates = prefs?['incidentUpdates'] as bool? ?? true;
    final systemAnnouncements = prefs?['systemAnnouncements'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Push Notifications',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _NotificationTile(
              icon: Icons.local_hospital,
              color: AppColors.critical,
              title: 'Incident Updates',
              subtitle:
                  'Receive real-time updates when your ambulance request is acknowledged, dispatched, en route, or resolved.',
              value: incidentUpdates,
              saving: _saving[_PrefKey.incidentUpdates]!,
              onChanged: (v) => _toggle(
                _PrefKey.incidentUpdates,
                incidentUpdates: v,
                systemAnnouncements: systemAnnouncements,
              ),
            ),
            const SizedBox(height: 8),
            _NotificationTile(
              icon: Icons.campaign,
              color: AppColors.primary,
              title: 'System Announcements',
              subtitle:
                  'Stay informed about service alerts, municipal advisories, and important community updates.',
              value: systemAnnouncements,
              saving: _saving[_PrefKey.systemAnnouncements]!,
              onChanged: (v) => _toggle(
                _PrefKey.systemAnnouncements,
                incidentUpdates: incidentUpdates,
                systemAnnouncements: v,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Contact Details in Emergencies',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your emergency contacts and medical info will be automatically shared with responders when you request an ambulance.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Writes immediately; the realtime stream echoes the result back into the UI.
  Future<void> _toggle(
    _PrefKey key, {
    required bool incidentUpdates,
    required bool systemAnnouncements,
  }) async {
    setState(() => _saving[key] = true);
    try {
      await _saveNotificationPrefs(
        ref,
        incidentUpdates: incidentUpdates,
        systemAnnouncements: systemAnnouncements,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving[key] = false);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    this.saving = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving) ...[
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Switch(
              value: value,
              onChanged: saving ? null : onChanged,
              activeThumbColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
