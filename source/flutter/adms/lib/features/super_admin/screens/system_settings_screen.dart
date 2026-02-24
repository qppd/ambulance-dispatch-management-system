import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/system_config_service.dart';
import '../../../core/theme/theme.dart';

// =============================================================================
// SYSTEM SETTINGS SCREEN  (Super Admin — wired to Firebase RTDB /systemConfig)
// =============================================================================

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  bool _saving = false;

  Future<void> _save() async {
    final configAsync = ref.read(systemConfigNotifierProvider);
    final config = configAsync.valueOrNull;
    if (config == null) return;

    final uid = ref.read(currentUserProvider)?.id ?? '';
    setState(() => _saving = true);

    try {
      final service = ref.read(systemConfigServiceProvider);
      final updated = config.copyWith(
        updatedAt: DateTime.now(),
        updatedByUid: uid,
      );
      await service.saveSystemConfig(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully.'),
            backgroundColor: AppColors.available,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editInt({
    required BuildContext context,
    required String title,
    required int current,
    required int min,
    required int max,
    required void Function(int) onSave,
  }) async {
    final ctrl = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter value ($min–$max)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v == null || v < min || v > max) return;
              Navigator.pop(context, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(systemConfigNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            FilledButton.icon(
              onPressed: configAsync.hasValue ? _save : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Changes'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: configAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) => _buildBody(context, config),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SystemConfig config) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Last updated metadata ───────────────────────────────────────
        if (config.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Last updated: ${_formatDate(config.updatedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

        // ── Section: Notifications ──────────────────────────────────────
        _SettingsSection(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          color: AppColors.primary,
          children: [
            _SwitchTile(
              title: 'Push Notifications',
              subtitle:
                  'Send real-time push alerts to dispatchers and drivers.',
              value: config.pushNotificationsEnabled,
              onChanged: (v) => ref
                  .read(systemConfigNotifierProvider.notifier)
                  .toggleBool(
                    (c) => c.pushNotificationsEnabled,
                    (c, val) => c.copyWith(pushNotificationsEnabled: val),
                  ),
            ),
            _SwitchTile(
              title: 'SMS Alerts',
              subtitle: 'Send SMS for critical incident updates.',
              value: config.smsAlertsEnabled,
              onChanged: (v) => ref
                  .read(systemConfigNotifierProvider.notifier)
                  .toggleBool(
                    (c) => c.smsAlertsEnabled,
                    (c, val) => c.copyWith(smsAlertsEnabled: val),
                  ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),

        // ── Section: Dispatch ───────────────────────────────────────────
        _SettingsSection(
          title: 'Dispatch',
          icon: Icons.route_outlined,
          color: AppColors.dispatcher,
          children: [
            _SwitchTile(
              title: 'Auto-Dispatch',
              subtitle:
                  'Automatically assign the nearest available unit.',
              value: config.autoDispatchEnabled,
              onChanged: (v) => ref
                  .read(systemConfigNotifierProvider.notifier)
                  .toggleBool(
                    (c) => c.autoDispatchEnabled,
                    (c, val) => c.copyWith(autoDispatchEnabled: val),
                  ),
            ),
            _IntTile(
              title: 'Response Time Threshold',
              subtitle:
                  'Flag incidents where response exceeds this limit (minutes).',
              value: config.responseTimeThresholdMinutes,
              unit: 'min',
              onTap: () => _editInt(
                context: context,
                title: 'Response Time Threshold (minutes)',
                current: config.responseTimeThresholdMinutes,
                min: 1,
                max: 120,
                onSave: (v) => ref
                    .read(systemConfigNotifierProvider.notifier)
                    .updateInt(
                      (c, val) => c.copyWith(
                          responseTimeThresholdMinutes: val),
                      v,
                    ),
              ),
            ),
          ],
        )
            .animate(delay: 80.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),

        // ── Section: Security ───────────────────────────────────────────
        _SettingsSection(
          title: 'Security',
          icon: Icons.security_outlined,
          color: AppColors.critical,
          children: [
            _SwitchTile(
              title: 'Require Admin Approval',
              subtitle:
                  'New accounts require Super Admin approval before login.',
              value: config.requireAdminApproval,
              onChanged: (v) => ref
                  .read(systemConfigNotifierProvider.notifier)
                  .toggleBool(
                    (c) => c.requireAdminApproval,
                    (c, val) => c.copyWith(requireAdminApproval: val),
                  ),
            ),
            _IntTile(
              title: 'Session Timeout',
              subtitle: 'Automatically log out idle users.',
              value: config.sessionTimeoutMinutes,
              unit: 'min',
              onTap: () => _editInt(
                context: context,
                title: 'Session Timeout (minutes)',
                current: config.sessionTimeoutMinutes,
                min: 5,
                max: 480,
                onSave: (v) => ref
                    .read(systemConfigNotifierProvider.notifier)
                    .updateInt(
                      (c, val) =>
                          c.copyWith(sessionTimeoutMinutes: val),
                      v,
                    ),
              ),
            ),
          ],
        )
            .animate(delay: 160.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0),
        const SizedBox(height: 32),

        // ── Unsaved changes reminder ────────────────────────────────────
        Card(
          color: AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes are saved to Firebase RTDB (/systemConfig) '
                    'only when you tap "Save Changes".',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: 240.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// REUSABLE SECTION WIDGET
// =============================================================================

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

// =============================================================================
// TOGGLE TILE
// =============================================================================

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
    );
  }
}

// =============================================================================
// INTEGER SETTING TILE
// =============================================================================

class _IntTile extends StatelessWidget {
  const _IntTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      trailing: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value $unit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
