import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Hospital management screen for Municipal Admin.
class HospitalsScreen extends ConsumerStatefulWidget {
  final String municipalityId;

  const HospitalsScreen({required this.municipalityId, super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  String _search = '';
  bool? _filterAccepting;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(municipalityHospitalsProvider(widget.municipalityId));

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
                    Text('Hospitals', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Manage hospital registrations and capacity', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Register Hospital'),
                onPressed: () => _showHospitalDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Filters
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search hospitals…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('All', _filterAccepting == null, () => setState(() => _filterAccepting = null)),
              const SizedBox(width: 6),
              _FilterChip('Accepting', _filterAccepting == true, () => setState(() => _filterAccepting = true)),
              const SizedBox(width: 6),
              _FilterChip('Not Accepting', _filterAccepting == false, () => setState(() => _filterAccepting = false)),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Stats
          hospitalsAsync.when(
            data: (h) => _HospitalStatsBar(hospitals: h),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // ─── Grid
          Expanded(
            child: hospitalsAsync.when(
              data: (hospitals) {
                final filtered = hospitals.where((h) {
                  final matchSearch = _search.isEmpty ||
                      h.name.toLowerCase().contains(_search) ||
                      h.address.toLowerCase().contains(_search);
                  final matchFilter = _filterAccepting == null || h.isAcceptingPatients == _filterAccepting;
                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('No hospitals found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _HospitalCard(
                    hospital: filtered[i],
                    onEdit: () => _showHospitalDialog(context, filtered[i]),
                    onToggleAccepting: () => _toggleAccepting(filtered[i]),
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

  void _showHospitalDialog(BuildContext context, Hospital? existing) {
    showDialog(context: context, builder: (ctx) => _HospitalDialog(
      municipalityId: widget.municipalityId,
      existing: existing,
    ));
  }

  Future<void> _toggleAccepting(Hospital hospital) async {
    final svc = ref.read(hospitalServiceProvider);
    try {
      await svc.setAcceptingPatients(
        municipalityId: hospital.municipalityId,
        hospitalId: hospital.id,
        isAccepting: !hospital.isAcceptingPatients,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${hospital.name} is now ${!hospital.isAcceptingPatients ? "accepting" : "not accepting"} patients'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Hospital hospital) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hospital?'),
        content: Text('Are you sure you want to remove ${hospital.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final svc = ref.read(hospitalServiceProvider);
      try {
        await svc.deleteHospital(municipalityId: hospital.municipalityId, hospitalId: hospital.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${hospital.name} removed'), behavior: SnackBarBehavior.floating));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Simple filter chip widget
// -----------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.municipalAdmin.withOpacity(0.12),
      checkmarkColor: AppColors.municipalAdmin,
    );
  }
}

// =============================================================================
// Stats Bar
// =============================================================================

class _HospitalStatsBar extends StatelessWidget {
  final List<Hospital> hospitals;

  const _HospitalStatsBar({required this.hospitals});

  @override
  Widget build(BuildContext context) {
    final total = hospitals.length;
    final accepting = hospitals.where((h) => h.isAcceptingPatients).length;
    final nearCapacity = hospitals.where((h) => h.isNearCapacity).length;
    final withICU = hospitals.where((h) => h.hasICU).length;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _chip('Total: $total', AppColors.primary),
        _chip('Accepting: $accepting', AppColors.available),
        _chip('Near Capacity: $nearCapacity', AppColors.critical),
        _chip('With ICU: $withICU', AppColors.dispatcher),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// =============================================================================
// Hospital Card
// =============================================================================

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onEdit, onToggleAccepting, onDelete;

  const _HospitalCard({required this.hospital, required this.onEdit, required this.onToggleAccepting, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final loadColor = hospital.isNearCapacity ? AppColors.critical : (hospital.emergencyLoadFactor >= 0.6 ? AppColors.urgent : AppColors.available);
    final loadPct = (hospital.emergencyLoadFactor * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'toggle') onToggleAccepting();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [
                      Icon(hospital.isAcceptingPatients ? Icons.block : Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Text(hospital.isAcceptingPatients ? 'Stop Accepting' : 'Accept Patients'),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.critical), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.critical))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ─ address
            Row(children: [
              const Icon(Icons.place_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text(hospital.address, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            // ─ emergency load bar
            Row(children: [
              const Text('ER Load: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hospital.emergencyLoadFactor,
                    backgroundColor: AppColors.border,
                    color: loadColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('$loadPct%', style: TextStyle(fontSize: 11, color: loadColor, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            // ─ capabilities
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                if (hospital.hasEmergencyRoom) _badge('ER', AppColors.critical),
                if (hospital.hasICU) _badge('ICU', AppColors.urgent),
                if (hospital.hasSurgery) _badge('Surgery', AppColors.enRoute),
                ...hospital.specialties.take(2).map((s) => _badge(s, AppColors.textSecondary)),
              ],
            ),
            const Spacer(),
            // ─ status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hospital.isAcceptingPatients ? AppColors.available.withOpacity(0.12) : AppColors.critical.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hospital.isAcceptingPatients ? 'Accepting Patients' : 'Not Accepting',
                    style: TextStyle(
                      color: hospital.isAcceptingPatients ? AppColors.available : AppColors.critical,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text('Beds: ${hospital.availableBeds}/${hospital.totalBeds}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// =============================================================================
// Hospital Add / Edit Dialog
// =============================================================================

class _HospitalDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  final Hospital? existing;

  const _HospitalDialog({required this.municipalityId, this.existing});

  @override
  ConsumerState<_HospitalDialog> createState() => _HospitalDialogState();
}

class _HospitalDialogState extends ConsumerState<_HospitalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _contact, _email, _lat, _lng, _beds, _erCap;
  bool _hasER = true, _hasICU = false, _hasSurgery = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _address = TextEditingController(text: h?.address ?? '');
    _contact = TextEditingController(text: h?.contactNumber ?? '');
    _email = TextEditingController(text: h?.email ?? '');
    _lat = TextEditingController(text: h?.latitude.toString() ?? '');
    _lng = TextEditingController(text: h?.longitude.toString() ?? '');
    _beds = TextEditingController(text: (h?.totalBeds ?? 0).toString());
    _erCap = TextEditingController(text: (h?.emergencyCapacity ?? 0).toString());
    _hasER = h?.hasEmergencyRoom ?? true;
    _hasICU = h?.hasICU ?? false;
    _hasSurgery = h?.hasSurgery ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _contact, _email, _lat, _lng, _beds, _erCap]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Hospital' : 'Register Hospital'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Hospital Name *'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address *'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact Number *'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: _lat, decoration: const InputDecoration(labelText: 'Latitude *'), keyboardType: TextInputType.number, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  })),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _lng, decoration: const InputDecoration(labelText: 'Longitude *'), keyboardType: TextInputType.number, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  })),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: _beds, decoration: const InputDecoration(labelText: 'Total Beds'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _erCap, decoration: const InputDecoration(labelText: 'ER Capacity'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                const Text('Capabilities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(label: const Text('Emergency Room'), selected: _hasER, onSelected: (v) => setState(() => _hasER = v)),
                    FilterChip(label: const Text('ICU'), selected: _hasICU, onSelected: (v) => setState(() => _hasICU = v)),
                    FilterChip(label: const Text('Surgery'), selected: _hasSurgery, onSelected: (v) => setState(() => _hasSurgery = v)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Update' : 'Register'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = ref.read(hospitalServiceProvider);
      final lat = double.parse(_lat.text);
      final lng = double.parse(_lng.text);
      final beds = int.tryParse(_beds.text) ?? 0;
      final erCap = int.tryParse(_erCap.text) ?? 0;

      if (widget.existing == null) {
        await svc.createHospital(
          id: const Uuid().v4(),
          municipalityId: widget.municipalityId,
          name: _name.text.trim(),
          address: _address.text.trim(),
          contactNumber: _contact.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          latitude: lat,
          longitude: lng,
          totalBeds: beds,
          emergencyCapacity: erCap,
          hasEmergencyRoom: _hasER,
          hasICU: _hasICU,
          hasSurgery: _hasSurgery,
        );
      } else {
        await svc.updateHospital(
          municipalityId: widget.municipalityId,
          hospitalId: widget.existing!.id,
          name: _name.text.trim(),
          address: _address.text.trim(),
          contactNumber: _contact.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          totalBeds: beds,
          emergencyCapacity: erCap,
          hasEmergencyRoom: _hasER,
          hasICU: _hasICU,
          hasSurgery: _hasSurgery,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
