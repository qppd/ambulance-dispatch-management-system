import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen for managing citizen notification preferences.
/// Accessible from: Profile > Notifications.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _incidentUpdates = true;
  bool _systemAnnouncements = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(citizenNotificationPrefsProvider).value;
    _incidentUpdates = prefs?['incidentUpdates'] as bool? ?? true;
    _systemAnnouncements = prefs?['systemAnnouncements'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
              value: _incidentUpdates,
              onChanged: (v) => setState(() => _incidentUpdates = v),
            ),
            const SizedBox(height: 8),
            _NotificationTile(
              icon: Icons.campaign,
              color: AppColors.primary,
              title: 'System Announcements',
              subtitle:
                  'Stay informed about service alerts, municipal advisories, and important community updates.',
              value: _systemAnnouncements,
              onChanged: (v) => setState(() => _systemAnnouncements = v),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _savePrefs,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrefs() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(citizenServiceProvider).saveNotificationPrefs(
            incidentUpdates: _incidentUpdates,
            systemAnnouncements: _systemAnnouncements,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ),
    );
  }
}
