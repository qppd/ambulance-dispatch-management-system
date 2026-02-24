import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';

// =============================================================================
// SYSTEM SETTINGS SCREEN  (scaffold — Super Admin only)
// =============================================================================

/// Global system configuration screen.
///
/// TODO: Persist settings via Firebase RTDB `/systemConfig` or
/// Firebase Remote Config.
class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Section: Notifications ──────────────────────────────────────
          _SettingsSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            color: AppColors.primary,
            children: const [
              _SettingsTile(
                title: 'Push Notifications',
                subtitle:
                    'Send real-time push alerts to dispatchers and drivers.',
                trailing: _PlaceholderSwitch(value: true),
              ),
              _SettingsTile(
                title: 'SMS Alerts',
                subtitle: 'Send SMS for critical incident updates.',
                trailing: _PlaceholderSwitch(value: false),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          // ── Section: Dispatch ───────────────────────────────────────────
          _SettingsSection(
            title: 'Dispatch',
            icon: Icons.route_outlined,
            color: AppColors.dispatcher,
            children: const [
              _SettingsTile(
                title: 'Auto-Dispatch',
                subtitle:
                    'Automatically assign the nearest available unit.',
                trailing: _PlaceholderSwitch(value: false),
              ),
              _SettingsTile(
                title: 'Response Time Threshold (min)',
                subtitle:
                    'Flag incidents where response exceeds this limit.',
                trailing: _PlaceholderText(label: '10'),
              ),
            ],
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          // ── Section: Security ───────────────────────────────────────────
          _SettingsSection(
            title: 'Security',
            icon: Icons.security_outlined,
            color: AppColors.critical,
            children: const [
              _SettingsTile(
                title: 'Require Admin Approval',
                subtitle:
                    'New accounts require Super Admin approval before login.',
                trailing: _PlaceholderSwitch(value: true),
              ),
              _SettingsTile(
                title: 'Session Timeout (minutes)',
                subtitle: 'Automatically log out idle users.',
                trailing: _PlaceholderText(label: '60'),
              ),
            ],
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          // ── Coming Soon banner ──────────────────────────────────────────
          Card(
            color: AppColors.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Settings persistence is not yet wired. Connect this '
                      'screen to Firebase RTDB /systemConfig or Remote Config '
                      'to save and load configuration values.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGETS
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      trailing: trailing,
    );
  }
}

class _PlaceholderSwitch extends StatelessWidget {
  const _PlaceholderSwitch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) =>
      Switch(value: value, onChanged: null); // null = disabled until wired
}

class _PlaceholderText extends StatelessWidget {
  const _PlaceholderText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.primary.withOpacity(0.08),
    );
  }
}
