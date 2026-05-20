import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Fleet maintenance management screen for Municipal Admin.
/// Shows all maintenance records, allows scheduling, and managing lifecycle.
class MaintenanceScreen extends ConsumerStatefulWidget {
  final String municipalityId;

  const MaintenanceScreen({required this.municipalityId, super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maintenance',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Schedule and track ambulance maintenance',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule'),
                onPressed: () => _showScheduleDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'All Records'),
              Tab(text: 'Completed'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _UpcomingTab(municipalityId: widget.municipalityId),
                _AllRecordsTab(municipalityId: widget.municipalityId),
                _CompletedTab(municipalityId: widget.municipalityId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    final unitsAsync =
        ref.read(municipalityUnitsProvider(widget.municipalityId));
    final units = unitsAsync.value ?? [];

    showDialog(
      context: context,
      builder: (ctx) => _ScheduleMaintenanceDialog(
        municipalityId: widget.municipalityId,
        units: units,
      ),
    );
  }
}

// =============================================================================
// Upcoming Tab
// =============================================================================

class _UpcomingTab extends ConsumerWidget {
  final String municipalityId;
  const _UpcomingTab({required this.municipalityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(municipalityId));

    return upcomingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.available),
                const SizedBox(height: 16),
                Text('No upcoming maintenance',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (ctx, i) => _MaintenanceCard(
            record: records[i],
          ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn().slideX(
              begin: 0.03, end: 0),
        );
      },
    );
  }
}

// =============================================================================
// All Records Tab
// =============================================================================

class _AllRecordsTab extends ConsumerWidget {
  final String municipalityId;
  const _AllRecordsTab({required this.municipalityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync =
        ref.watch(municipalityMaintenanceProvider(municipalityId));

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Text('No maintenance records yet.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          );
        }
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (ctx, i) => _MaintenanceCard(record: records[i]),
        );
      },
    );
  }
}

// =============================================================================
// Completed Tab
// =============================================================================

class _CompletedTab extends ConsumerWidget {
  final String municipalityId;
  const _CompletedTab({required this.municipalityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync =
        ref.watch(municipalityMaintenanceProvider(municipalityId));

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        final completed = records
            .where((r) => r.status == MaintenanceStatus.completed)
            .toList();
        if (completed.isEmpty) {
          return Center(
            child: Text('No completed records.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          );
        }
        return ListView.builder(
          itemCount: completed.length,
          itemBuilder: (ctx, i) =>
              _MaintenanceCard(record: completed[i]),
        );
      },
    );
  }
}

// =============================================================================
// Maintenance Card
// =============================================================================

class _MaintenanceCard extends ConsumerWidget {
  final MaintenanceRecord record;

  const _MaintenanceCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(record.status);
    final isOverdue = record.isOverdue;
    final df = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: AppColors.critical, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(record.type),
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.unitCallSign,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(record.type.displayName,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverdue ? 'Overdue' : record.status.displayName,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(record.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Scheduled: ${df.format(record.scheduledDate)}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (record.completedDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 13, color: AppColors.available),
                  const SizedBox(width: 4),
                  Text('Done: ${df.format(record.completedDate!)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.available)),
                ],
              ],
            ),
            if (record.status != MaintenanceStatus.completed &&
                record.status != MaintenanceStatus.cancelled) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (record.status == MaintenanceStatus.scheduled)
                    TextButton(
                      onPressed: () => _startMaintenance(context, ref),
                      child: const Text('Start'),
                    ),
                  if (record.status == MaintenanceStatus.inProgress ||
                      record.status == MaintenanceStatus.scheduled)
                    TextButton(
                      onPressed: () =>
                          _showCompleteDialog(context, ref),
                      child: const Text('Complete'),
                    ),
                  TextButton(
                    onPressed: () => _cancel(context, ref),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.critical)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startMaintenance(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(maintenanceServiceProvider).startMaintenance(
            municipalityId: record.municipalityId,
            maintenanceId: record.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(maintenanceServiceProvider).cancelMaintenance(
            municipalityId: record.municipalityId,
            maintenanceId: record.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    final notesCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final performedByCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Maintenance'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: performedByCtrl,
                decoration: const InputDecoration(
                    labelText: 'Performed By', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cost', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(maintenanceServiceProvider).completeMaintenance(
                      municipalityId: record.municipalityId,
                      maintenanceId: record.id,
                      performedBy: performedByCtrl.text.isNotEmpty
                          ? performedByCtrl.text
                          : null,
                      cost: double.tryParse(costCtrl.text),
                      notes:
                          notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(MaintenanceStatus s) {
    switch (s) {
      case MaintenanceStatus.scheduled:
        return AppColors.primary;
      case MaintenanceStatus.inProgress:
        return AppColors.enRoute;
      case MaintenanceStatus.completed:
        return AppColors.available;
      case MaintenanceStatus.overdue:
        return AppColors.critical;
      case MaintenanceStatus.cancelled:
        return AppColors.outOfService;
    }
  }

  IconData _typeIcon(MaintenanceType t) {
    switch (t) {
      case MaintenanceType.preventive:
        return Icons.build_outlined;
      case MaintenanceType.corrective:
        return Icons.handyman_outlined;
      case MaintenanceType.inspection:
        return Icons.checklist_outlined;
      case MaintenanceType.equipment:
        return Icons.medical_services_outlined;
    }
  }
}

// =============================================================================
// Schedule Maintenance Dialog
// =============================================================================

class _ScheduleMaintenanceDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  final List<AmbulanceUnit> units;

  const _ScheduleMaintenanceDialog({
    required this.municipalityId,
    required this.units,
  });

  @override
  ConsumerState<_ScheduleMaintenanceDialog> createState() =>
      _ScheduleMaintenanceDialogState();
}

class _ScheduleMaintenanceDialogState
    extends ConsumerState<_ScheduleMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  AmbulanceUnit? _selectedUnit;
  MaintenanceType _type = MaintenanceType.preventive;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Maintenance'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AmbulanceUnit>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                      labelText: 'Ambulance Unit',
                      border: OutlineInputBorder()),
                  items: widget.units
                      .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                              '${u.callSign} (${u.plateNumber})')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                  validator: (v) => v == null ? 'Select a unit' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MaintenanceType>(
                  value: _type,
                  decoration: const InputDecoration(
                      labelText: 'Maintenance Type',
                      border: OutlineInputBorder()),
                  items: MaintenanceType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _type = v ?? MaintenanceType.preventive),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the maintenance work…',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      'Scheduled: ${DateFormat.yMMMd().format(_scheduledDate)}'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _scheduledDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Schedule'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(maintenanceServiceProvider).scheduleMaintenance(
            municipalityId: widget.municipalityId,
            unitId: _selectedUnit!.id,
            unitCallSign: _selectedUnit!.callSign,
            type: _type,
            description: _descCtrl.text.trim(),
            scheduledDate: _scheduledDate,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maintenance scheduled.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
