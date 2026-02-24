import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

// =============================================================================
// MUNICIPALITY MANAGEMENT SCREEN
// =============================================================================

/// Full CRUD management screen for municipalities — Super Admin only.
///
/// Streams all municipalities (active + inactive) via
/// [allMunicipalitiesManagementProvider] and exposes add, edit,
/// activate/deactivate and delete operations through the [MunicipalityService].
class MunicipalityManagementScreen extends ConsumerWidget {
  const MunicipalityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipalitiesAsync = ref.watch(allMunicipalitiesManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Municipalities'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showForm(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: municipalitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.critical),
                const SizedBox(height: 16),
                Text('Error loading municipalities: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.critical)),
              ],
            ),
          ),
        ),
        data: (municipalities) {
          if (municipalities.isEmpty) {
            return _EmptyMunicipalitiesState(
                onAdd: () => _showForm(context, ref));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: municipalities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _MunicipalityTile(
                municipality: municipalities[index],
                onEdit: (m) => _showForm(context, ref, existing: m),
              )
                  .animate(delay: Duration(milliseconds: 40 * index))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, end: 0);
            },
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {Municipality? existing}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MunicipalityFormDialog(existing: existing),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptyMunicipalitiesState extends StatelessWidget {
  const _EmptyMunicipalitiesState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city_outlined,
              size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No municipalities registered.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the first municipality to get started.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Municipality'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MUNICIPALITY TILE
// =============================================================================

class _MunicipalityTile extends ConsumerWidget {
  const _MunicipalityTile({
    required this.municipality,
    required this.onEdit,
  });

  final Municipality municipality;
  final void Function(Municipality) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = municipality.isActive;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isActive
                    ? AppColors.municipalAdmin
                    : AppColors.textMuted)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_city,
            color: isActive ? AppColors.municipalAdmin : AppColors.textMuted,
            size: 22,
          ),
        ),
        title: Text(
          municipality.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${municipality.province} • ${municipality.region}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _StatChip(
                  icon: Icons.local_shipping_outlined,
                  label:
                      '${municipality.activeUnits}/${municipality.totalUnits} units',
                  color: AppColors.driver,
                ),
                _StatChip(
                  icon: Icons.local_hospital_outlined,
                  label: '${municipality.totalHospitals} hospitals',
                  color: AppColors.hospitalStaff,
                ),
                _StatChip(
                  icon: Icons.headset_mic_outlined,
                  label: '${municipality.totalDispatchers} dispatchers',
                  color: AppColors.dispatcher,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active/Inactive badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.available.withOpacity(0.15)
                    : AppColors.outOfService.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive
                      ? AppColors.available
                      : AppColors.outOfService,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Actions menu
            PopupMenuButton<_TileAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Actions',
              onSelected: (action) =>
                  _handleAction(context, ref, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _TileAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _TileAction.toggleActive,
                  child: ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    title: Text(isActive ? 'Deactivate' : 'Activate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _TileAction.delete,
                  child: ListTile(
                    leading:
                        Icon(Icons.delete_outline, color: AppColors.critical),
                    title: Text('Delete',
                        style: TextStyle(color: AppColors.critical)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, _TileAction action) async {
    switch (action) {
      case _TileAction.edit:
        onEdit(municipality);
      case _TileAction.toggleActive:
        await _toggleActive(context, ref);
      case _TileAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final newStatus = !municipality.isActive;
    try {
      await ref.read(municipalityServiceProvider).setActive(
            municipalityId: municipality.id,
            isActive: newStatus,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${municipality.name} has been ${newStatus ? 'activated' : 'deactivated'}.'),
          backgroundColor:
              newStatus ? AppColors.available : AppColors.outOfService,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: AppColors.critical, size: 32),
        title: const Text('Delete Municipality'),
        content: Text(
          'Permanently delete "${municipality.name}"?\n\n'
          'All associated data will be lost. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(municipalityServiceProvider)
          .deleteMunicipality(municipality.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${municipality.name}" has been deleted.'),
          backgroundColor: AppColors.critical,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
      }
    }
  }
}

// =============================================================================
// STAT CHIP
// =============================================================================

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// =============================================================================
// ADD / EDIT FORM DIALOG
// =============================================================================

/// Modal dialog for adding or editing a municipality.
///
/// Uses [ConsumerStatefulWidget] so the form state and the
/// [MunicipalityService] are both accessible without prop-drilling.
class _MunicipalityFormDialog extends ConsumerStatefulWidget {
  const _MunicipalityFormDialog({this.existing});

  final Municipality? existing;

  @override
  ConsumerState<_MunicipalityFormDialog> createState() =>
      _MunicipalityFormDialogState();
}

class _MunicipalityFormDialogState
    extends ConsumerState<_MunicipalityFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _hotlineCtrl;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _provinceCtrl = TextEditingController(text: m?.province ?? '');
    _regionCtrl = TextEditingController(text: m?.region ?? '');
    _contactCtrl = TextEditingController(text: m?.contactNumber ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _hotlineCtrl = TextEditingController(text: m?.emergencyHotline ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _provinceCtrl.dispose();
    _regionCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _hotlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final service = ref.read(municipalityServiceProvider);
    final name = _nameCtrl.text.trim();
    final province = _provinceCtrl.text.trim();
    final region = _regionCtrl.text.trim();
    final contactNumber =
        _contactCtrl.text.trim().isNotEmpty ? _contactCtrl.text.trim() : null;
    final email =
        _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null;
    final hotline = _hotlineCtrl.text.trim().isNotEmpty
        ? _hotlineCtrl.text.trim()
        : null;

    try {
      if (_isEdit) {
        await service.updateMunicipality(
          municipalityId: widget.existing!.id,
          name: name,
          province: province,
          region: region,
          contactNumber: contactNumber,
          email: email,
          emergencyHotline: hotline,
        );
      } else {
        await service.createMunicipality(
          id: const Uuid().v4(),
          name: name,
          province: province,
          region: region,
          contactNumber: contactNumber,
          email: email,
          emergencyHotline: hotline,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'Municipality updated successfully.'
              : 'Municipality "$name" added successfully.'),
          backgroundColor: AppColors.available,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
        setState(() => _saving = false);
      }
    }
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Municipality' : 'Add Municipality'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Required ──────────────────────────────────────────────
                _SectionLabel(label: 'Required'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Municipality Name *',
                    hintText: 'e.g. City of Davao',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _provinceCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Province *',
                    hintText: 'e.g. Davao del Sur',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Province is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Region *',
                    hintText: 'e.g. Region XI',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Region is required.'
                      : null,
                ),
                const SizedBox(height: 20),

                // ── Optional ──────────────────────────────────────────────
                _SectionLabel(label: 'Optional'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: 'e.g. +63-82-123-4567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'e.g. admin@davao.gov.ph',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return _emailRegex.hasMatch(v.trim())
                        ? null
                        : 'Enter a valid email address.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hotlineCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Hotline',
                    hintText: 'e.g. 911',
                    prefixIcon: Icon(Icons.emergency_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save Changes' : 'Add Municipality'),
        ),
      ],
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

enum _TileAction { edit, toggleActive, delete }
