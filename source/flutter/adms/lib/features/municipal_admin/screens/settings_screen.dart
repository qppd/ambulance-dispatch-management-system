import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Settings screen — municipality profile, hotline, and account management.
class SettingsScreen extends ConsumerStatefulWidget {
  final String municipalityId;

  const SettingsScreen({required this.municipalityId, super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _activeSetting = 0;

  static const _settingsSections = [
    (Icons.location_city_outlined, 'Municipality Profile'),
    (Icons.phone_outlined, 'Emergency Hotline'),
    (Icons.person_outline, 'My Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final municipalityAsync = ref.watch(municipalityProvider(widget.municipalityId));
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('Configure your municipality and account settings', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 700;
              final sidebar = _SettingsSidebar(
                items: _settingsSections,
                selectedIndex: _activeSetting,
                onSelect: (i) => setState(() => _activeSetting = i),
              );
              final content = municipalityAsync.when(
                data: (muni) => _SettingsContent(
                  sectionIndex: _activeSetting,
                  municipality: muni,
                  currentUser: currentUser,
                  municipalityId: widget.municipalityId,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 220, child: sidebar),
                      const SizedBox(width: 24),
                      Expanded(child: content),
                    ])
                  : Column(children: [sidebar, const SizedBox(height: 16), Expanded(child: content)]);
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sidebar
// =============================================================================

class _SettingsSidebar extends StatelessWidget {
  final List<(IconData, String)> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SettingsSidebar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (ctx, i) {
          final (icon, label) = items[i];
          final selected = i == selectedIndex;
          return ListTile(
            leading: Icon(icon, size: 18, color: selected ? AppColors.municipalAdmin : AppColors.textSecondary),
            title: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.municipalAdmin : AppColors.textPrimary)),
            selected: selected,
            selectedTileColor: AppColors.municipalAdmin.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            dense: true,
            onTap: () => onSelect(i),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Settings Content Router
// =============================================================================

class _SettingsContent extends ConsumerWidget {
  final int sectionIndex;
  final Municipality? municipality;
  final User? currentUser;
  final String municipalityId;

  const _SettingsContent({
    required this.sectionIndex,
    required this.municipality,
    required this.currentUser,
    required this.municipalityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (sectionIndex) {
      0 => _MunicipalityProfileSettings(municipality: municipality, municipalityId: municipalityId),
      1 => _EmergencyHotlineSettings(municipality: municipality, municipalityId: municipalityId),
      2 => _AccountSettings(user: currentUser),
      _ => const SizedBox.shrink(),
    };
  }
}

// =============================================================================
// Municipality Profile Settings
// =============================================================================

class _MunicipalityProfileSettings extends ConsumerStatefulWidget {
  final Municipality? municipality;
  final String municipalityId;

  const _MunicipalityProfileSettings({required this.municipality, required this.municipalityId});

  @override
  ConsumerState<_MunicipalityProfileSettings> createState() => _MunicipalityProfileSettingsState();
}

class _MunicipalityProfileSettingsState extends ConsumerState<_MunicipalityProfileSettings> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _province, _region, _contact, _email, _lat, _lng;
  bool _loading = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final m = widget.municipality;
    _name = TextEditingController(text: m?.name ?? '');
    _province = TextEditingController(text: m?.province ?? '');
    _region = TextEditingController(text: m?.region ?? '');
    _contact = TextEditingController(text: m?.contactNumber ?? '');
    _email = TextEditingController(text: m?.email ?? '');
    _lat = TextEditingController(text: m?.centerLatitude?.toString() ?? '');
    _lng = TextEditingController(text: m?.centerLongitude?.toString() ?? '');

    for (final ctrl in [_name, _province, _region, _contact, _email, _lat, _lng]) {
      ctrl.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _province, _region, _contact, _email, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Municipality Profile', "Update your municipality's basic information."),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldRow(
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Municipality Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                      TextFormField(controller: _province, decoration: const InputDecoration(labelText: 'Province *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    ),
                    const SizedBox(height: 14),
                    _fieldRow(
                      TextFormField(controller: _region, decoration: const InputDecoration(labelText: 'Region *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                      TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact Number')),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email Address')),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),
                    Text('Map Center Coordinates', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _fieldRow(
                      TextFormField(controller: _lat, decoration: const InputDecoration(labelText: 'Center Latitude'), keyboardType: TextInputType.number, validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Invalid';
                        return null;
                      }),
                      TextFormField(controller: _lng, decoration: const InputDecoration(labelText: 'Center Longitude'), keyboardType: TextInputType.number, validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Invalid';
                        return null;
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (_dirty) TextButton(onPressed: _reset, child: const Text('Reset')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _fieldRow(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)],
    );
  }

  void _reset() {
    final m = widget.municipality;
    _name.text = m?.name ?? '';
    _province.text = m?.province ?? '';
    _region.text = m?.region ?? '';
    _contact.text = m?.contactNumber ?? '';
    _email.text = m?.email ?? '';
    _lat.text = m?.centerLatitude?.toString() ?? '';
    _lng.text = m?.centerLongitude?.toString() ?? '';
    setState(() => _dirty = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = ref.read(municipalityServiceProvider);
      await svc.updateMunicipality(
        municipalityId: widget.municipalityId,
        name: _name.text.trim(),
        province: _province.text.trim(),
        region: _region.text.trim(),
        contactNumber: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        centerLatitude: double.tryParse(_lat.text),
        centerLongitude: double.tryParse(_lng.text),
      );
      setState(() => _dirty = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Municipality profile updated.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// =============================================================================
// Emergency Hotline Settings
// =============================================================================

class _EmergencyHotlineSettings extends ConsumerStatefulWidget {
  final Municipality? municipality;
  final String municipalityId;

  const _EmergencyHotlineSettings({required this.municipality, required this.municipalityId});

  @override
  ConsumerState<_EmergencyHotlineSettings> createState() => _EmergencyHotlineSettingsState();
}

class _EmergencyHotlineSettingsState extends ConsumerState<_EmergencyHotlineSettings> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hotline;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _hotline = TextEditingController(text: widget.municipality?.emergencyHotline ?? '');
  }

  @override
  void dispose() {
    _hotline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Emergency Hotline', 'Set the public-facing emergency contact number.'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.critical.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_in_talk_outlined, color: AppColors.critical, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Hotline', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.critical)),
                                Text(
                                  widget.municipality?.emergencyHotline ?? 'Not set',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.critical),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _hotline,
                      decoration: const InputDecoration(labelText: 'Emergency Hotline Number', hintText: 'e.g. 0916-XXX-XXXX or 911', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Cannot be empty' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update Hotline'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = ref.read(municipalityServiceProvider);
      await svc.updateMunicipality(municipalityId: widget.municipalityId, emergencyHotline: _hotline.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Emergency hotline updated.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// =============================================================================
// Account Settings
// =============================================================================

class _AccountSettings extends ConsumerWidget {
  final User? user;

  const _AccountSettings({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const Center(child: Text('Not signed in.'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'My Account', 'Your admin account information.'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─ Avatar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.municipalAdmin.withOpacity(0.15),
                        child: Text(
                          user!.initials,
                          style: const TextStyle(color: AppColors.municipalAdmin, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user!.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(user!.role.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _infoRow(context, Icons.email_outlined, 'Email', user!.email),
                  if (user!.phoneNumber != null) _infoRow(context, Icons.phone_outlined, 'Phone', user!.phoneNumber!),
                  _infoRow(context, Icons.location_city_outlined, 'Municipality', user!.municipalityName ?? user!.municipalityId ?? 'N/A'),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Security', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                      onPressed: () => ref.read(authStateProvider.notifier).logout(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// reference the enclosing class's widget (no widget field in ConsumerWidget, use user directly)
  String get municipalityId => user?.municipalityId ?? '';
}

// =============================================================================
// Helpers
// =============================================================================

Widget _sectionHeader(BuildContext context, String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
    ],
  );
}
