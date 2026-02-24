import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Full ambulance unit management screen for Municipal Admin.
class AmbulancesScreen extends ConsumerStatefulWidget {
  final String municipalityId;

  const AmbulancesScreen({required this.municipalityId, super.key});

  @override
  ConsumerState<AmbulancesScreen> createState() => _AmbulancesScreenState();
}

class _AmbulancesScreenState extends ConsumerState<AmbulancesScreen> {
  UnitStatus? _filterStatus;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(municipalityUnitsProvider(widget.municipalityId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambulances', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Manage ambulance fleet and driver assignments', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Unit'),
                onPressed: () => _showUnitDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Search + Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search call sign or plate…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusFilter(),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Stats chips
          unitsAsync.when(
            data: (units) => _StatsBar(units: units),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // ─── Units grid
          Expanded(
            child: unitsAsync.when(
              data: (units) {
                var filtered = units.where((u) {
                  final matchStatus = _filterStatus == null || u.status == _filterStatus;
                  final matchSearch = _search.isEmpty ||
                      u.callSign.toLowerCase().contains(_search) ||
                      u.plateNumber.toLowerCase().contains(_search) ||
                      (u.assignedDriverName?.toLowerCase().contains(_search) ?? false);
                  return matchStatus && matchSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('No units found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _UnitCard(
                    unit: filtered[i],
                    onEdit: () => _showUnitDialog(context, filtered[i]),
                    onToggleActive: () => _toggleActive(filtered[i]),
                    onDelete: () => _confirmDelete(context, filtered[i]),
                  ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn().scale(begin: const Offset(0.96, 0.96)),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<UnitStatus?>(
      tooltip: 'Filter by status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: _filterStatus != null ? AppColors.municipalAdmin.withOpacity(0.06) : null,
        ),
        child: Row(children: [
          const Icon(Icons.filter_list, size: 18),
          const SizedBox(width: 6),
          Text(_filterStatus?.displayName ?? 'All Status', style: const TextStyle(fontSize: 13)),
        ]),
      ),
      onSelected: (v) => setState(() => _filterStatus = v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All Status')),
        ...UnitStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.displayName))),
      ],
    );
  }

  void _showUnitDialog(BuildContext context, AmbulanceUnit? existing) {
    showDialog(context: context, builder: (ctx) => _UnitDialog(
      municipalityId: widget.municipalityId,
      existing: existing,
    ));
  }

  void _toggleActive(AmbulanceUnit unit) async {
    final service = ref.read(unitServiceProvider);
    try {
      await service.setActive(
        municipalityId: unit.municipalityId,
        unitId: unit.id,
        isActive: !unit.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${unit.callSign} ${!unit.isActive ? "activated" : "deactivated"}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _confirmDelete(BuildContext context, AmbulanceUnit unit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text('Are you sure you want to delete ${unit.callSign}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () async {
              Navigator.pop(ctx);
              final service = ref.read(unitServiceProvider);
              try {
                await service.deleteUnit(municipalityId: unit.municipalityId, unitId: unit.id);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${unit.callSign} deleted'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stats bar
// -----------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  final List<AmbulanceUnit> units;

  const _StatsBar({required this.units});

  @override
  Widget build(BuildContext context) {
    final counts = <UnitStatus, int>{};
    for (final s in UnitStatus.values) {
      counts[s] = units.where((u) => u.status == s).length;
    }
    final colors = {
      UnitStatus.available: AppColors.available,
      UnitStatus.enRoute: AppColors.enRoute,
      UnitStatus.onScene: AppColors.onScene,
      UnitStatus.transporting: AppColors.transporting,
      UnitStatus.atHospital: AppColors.atHospital,
      UnitStatus.outOfService: AppColors.outOfService,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: UnitStatus.values.map((s) {
        final c = colors[s]!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.25)),
          ),
          child: Text(
            '${s.displayName}: ${counts[s]}',
            style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// Unit Card
// -----------------------------------------------------------------------------

class _UnitCard extends StatelessWidget {
  final AmbulanceUnit unit;
  final VoidCallback onEdit, onToggleActive, onDelete;

  const _UnitCard({required this.unit, required this.onEdit, required this.onToggleActive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(unit.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.local_shipping, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.callSign, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(unit.plateNumber, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'toggle') onToggleActive();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 16), const SizedBox(width: 8), const Text('Edit')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [Icon(unit.isActive ? Icons.block : Icons.check_circle, size: 16), const SizedBox(width: 8), Text(unit.isActive ? 'Deactivate' : 'Activate')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.critical), const SizedBox(width: 8), const Text('Delete', style: TextStyle(color: AppColors.critical))])),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // ─ type badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(unit.type.displayName, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                if (!unit.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.outOfService.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Inactive', style: TextStyle(color: AppColors.outOfService, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // ─ status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(unit.status.displayName, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            // ─ driver
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    unit.assignedDriverName ?? 'No driver assigned',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(UnitStatus s) {
    switch (s) {
      case UnitStatus.available: return AppColors.available;
      case UnitStatus.enRoute: return AppColors.enRoute;
      case UnitStatus.onScene: return AppColors.onScene;
      case UnitStatus.transporting: return AppColors.transporting;
      case UnitStatus.atHospital: return AppColors.atHospital;
      case UnitStatus.outOfService: return AppColors.outOfService;
    }
  }
}

// -----------------------------------------------------------------------------
// Add / Edit Unit Dialog
// -----------------------------------------------------------------------------

class _UnitDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  final AmbulanceUnit? existing;

  const _UnitDialog({required this.municipalityId, this.existing});

  @override
  ConsumerState<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends ConsumerState<_UnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _callSign;
  late final TextEditingController _plate;
  UnitType _type = UnitType.bls;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _callSign = TextEditingController(text: widget.existing?.callSign ?? '');
    _plate = TextEditingController(text: widget.existing?.plateNumber ?? '');
    _type = widget.existing?.type ?? UnitType.bls;
  }

  @override
  void dispose() {
    _callSign.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Unit' : 'Add Ambulance Unit'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _callSign,
                decoration: const InputDecoration(labelText: 'Call Sign', hintText: 'e.g. AMB-001'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plate,
                decoration: const InputDecoration(labelText: 'Plate Number', hintText: 'e.g. ABC 1234'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UnitType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Unit Type'),
                items: UnitType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                onChanged: (v) => setState(() => _type = v ?? UnitType.bls),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Add Unit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(unitServiceProvider);

      if (widget.existing == null) {
        // Create new unit
        final id = const Uuid().v4();
        await service.createUnit(
          id: id,
          municipalityId: widget.municipalityId,
          callSign: _callSign.text.trim(),
          plateNumber: _plate.text.trim(),
          type: _type,
        );
      } else {
        // Update existing unit — patch call sign, plate, type via RTDB
        final dbRef = ref.read(databaseRefProvider);
        await dbRef.child('units/${widget.municipalityId}/${widget.existing!.id}').update({
          'callSign': _callSign.text.trim(),
          'plateNumber': _plate.text.trim(),
          'type': _type.toJson(),
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
