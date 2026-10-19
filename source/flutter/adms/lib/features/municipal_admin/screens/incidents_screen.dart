import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

enum _IncidentFilter { all, active, resolved, cancelled }

/// Full incident management screen for Municipal Admin or Dispatcher.
class IncidentsScreen extends ConsumerStatefulWidget {
  final String? municipalityId;

  const IncidentsScreen({this.municipalityId, super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  _IncidentFilter _filter = _IncidentFilter.active;
  IncidentSeverity? _severity;
  String _search = '';
  final _searchCtrl = TextEditingController();
  Incident? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final resolvedMunicipalityId =
        widget.municipalityId ?? user?.municipalityId;
    if (resolvedMunicipalityId == null) {
      return const Center(
        child: Text('No municipality assigned. Contact your administrator.'),
      );
    }
    final incidentsAsync = ref.watch(
      allMunicipalityIncidentsProvider(resolvedMunicipalityId),
    );
    final isWide = MediaQuery.of(context).size.width > 1100;

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
                    Text(
                      'Incidents',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Monitor and manage all emergency incidents',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Manual request on behalf of a citizen (cellular call / chat).
              FilledButton.icon(
                icon: const Icon(Icons.add_call, size: 18),
                label: const Text('New Request'),
                onPressed: () => _showManualRequestDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Filters row
          Row(
            children: [
              // Status filter
              ..._IncidentFilter.values.map((f) {
                final isActive = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                    selected: isActive,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.municipalAdmin.withValues(
                      alpha: 0.15,
                    ),
                    checkmarkColor: AppColors.municipalAdmin,
                  ),
                );
              }),
              const Spacer(),
              // Severity filter
              _SeverityFilterDropdown(
                value: _severity,
                onChanged: (v) => setState(() => _severity = v),
              ),
              const SizedBox(width: 10),
              // Search
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search incidents…',
                    prefixIcon: const Icon(Icons.search, size: 16),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Summary bar
          incidentsAsync.when(
            data: (all) => _SummaryBar(incidents: all),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Main content
          Expanded(
            child: incidentsAsync.when(
              data: (all) {
                final filtered = _applyFilters(all);

                // Re-resolve the selected incident against the freshest stream
                // data so the detail panel (and its action buttons, e.g.
                // Acknowledge → Dispatch) updates live instead of showing the
                // snapshot captured at tap time. Cleared if it disappears.
                Incident? selected;
                if (_selected != null) {
                  for (final inc in filtered) {
                    if (inc.id == _selected!.id) {
                      selected = inc;
                      break;
                    }
                  }
                  // Incident may have dropped out of the current filter —
                  // fall back to the unfiltered list so it isn't lost.
                  if (selected == null) {
                    for (final inc in all) {
                      if (inc.id == _selected!.id) {
                        selected = inc;
                        break;
                      }
                    }
                  }
                }

                if (filtered.isEmpty && selected == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency_outlined,
                          size: 64,
                          color: AppColors.textMutedOf(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No incidents found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textMutedOf(context)),
                        ),
                      ],
                    ),
                  );
                }

                final list = _IncidentList(
                  incidents: filtered,
                  selected: selected,
                  onSelect: (inc) =>
                      setState(() => _selected = inc.id == _selected?.id
                          ? null
                          : inc),
                );

                if (!isWide || selected == null) return list;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: list),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: _IncidentDetailPanel(
                        incident: selected,
                        onClose: () => setState(() => _selected = null),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  userErrorMessage(e),
                  style: const TextStyle(color: AppColors.critical),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Incident> _applyFilters(List<Incident> incidents) {
    return incidents.where((inc) {
      final matchFilter = switch (_filter) {
        _IncidentFilter.all => true,
        _IncidentFilter.active => inc.status.isActive,
        _IncidentFilter.resolved => inc.status == IncidentStatus.resolved,
        _IncidentFilter.cancelled => inc.status == IncidentStatus.cancelled,
      };
      final matchSeverity = _severity == null || inc.severity == _severity;
      final matchSearch =
          _search.isEmpty ||
          inc.description.toLowerCase().contains(_search) ||
          (inc.address?.toLowerCase().contains(_search) ?? false) ||
          (inc.reporterName?.toLowerCase().contains(_search) ?? false) ||
          inc.incidentType.toLowerCase().contains(_search);
      return matchFilter && matchSeverity && matchSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Manual (on-behalf-of-citizen) request
  // ---------------------------------------------------------------------------

  /// Open the form a municipal admin uses to log a request that came in over
  /// the phone or via Facebook chat. The admin types the caller's details and
  /// drops a pin on the map so the system captures the exact lat/lng.
  void _showManualRequestDialog(BuildContext context) {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: widget.municipalityId,
      action: 'logging a new request',
    )) {
      return;
    }
    final municipalityId = widget.municipalityId;
    if (municipalityId == null || municipalityId.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _ManualRequestDialog(municipalityId: municipalityId),
    );
  }
}

// =============================================================================
// Severity Filter Dropdown
// =============================================================================

/// Sentinel for the severity dropdown.
///
/// A `PopupMenuItem` whose value is `null` never fires `onSelected` — Flutter
/// treats a `null` result as "menu dismissed" and calls `onCanceled` instead,
/// which is why "All Severity" could never be re-selected. Wrapping the choice
/// in a non-nullable enum gives "All" a real value so the filter resets.
enum _SeverityChoice {
  all,
  critical,
  urgent,
  normal;

  IncidentSeverity? get severity => switch (this) {
    _SeverityChoice.all => null,
    _SeverityChoice.critical => IncidentSeverity.critical,
    _SeverityChoice.urgent => IncidentSeverity.urgent,
    _SeverityChoice.normal => IncidentSeverity.normal,
  };
}

class _SeverityFilterDropdown extends StatelessWidget {
  final IncidentSeverity? value;
  final ValueChanged<IncidentSeverity?> onChanged;

  const _SeverityFilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SeverityChoice>(
      tooltip: 'Filter by severity',
      onSelected: (choice) => onChanged(choice.severity),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _SeverityChoice.all,
          child: Text('All Severity'),
        ),
        ..._SeverityChoice.values.where((c) => c != _SeverityChoice.all).map((
          c,
        ) {
          final s = c.severity!;
          return PopupMenuItem(
            value: c,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _severityColor(s),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.displayName),
              ],
            ),
          );
        }),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderOf(context)),
          borderRadius: BorderRadius.circular(8),
          color: value != null
              ? AppColors.municipalAdmin.withValues(alpha: 0.06)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 16,
              color: value != null
                  ? _severityColor(value!)
                  : AppColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              value?.displayName ?? 'All Severity',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }
}

// =============================================================================
// Summary Bar
// =============================================================================

class _SummaryBar extends StatelessWidget {
  final List<Incident> incidents;

  const _SummaryBar({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final active = incidents.where((i) => i.status.isActive).length;
    final resolved = incidents
        .where((i) => i.status == IncidentStatus.resolved)
        .length;
    final cancelled = incidents
        .where((i) => i.status == IncidentStatus.cancelled)
        .length;
    final critical = incidents
        .where(
          (i) => i.severity == IncidentSeverity.critical && i.status.isActive,
        )
        .length;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _chip('Total: ${incidents.length}', AppColors.textSecondary),
        _chip('Active: $active', AppColors.enRoute),
        _chip('Critical: $critical', AppColors.critical),
        _chip('Resolved: $resolved', AppColors.available),
        _chip('Cancelled: $cancelled', AppColors.textMuted),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// Incident List
// =============================================================================

class _IncidentList extends StatelessWidget {
  final List<Incident> incidents;
  final Incident? selected;
  final void Function(Incident) onSelect;

  const _IncidentList({
    required this.incidents,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: incidents.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final inc = incidents[i];
          final color = _severityColor(inc.severity);
          final isSelected = selected?.id == inc.id;
          return InkWell(
            onTap: () => onSelect(inc),
            child: Container(
              color: isSelected
                  ? AppColors.municipalAdmin.withValues(alpha: 0.04)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                inc.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _severityBadge(inc.severity, color),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                inc.address ?? 'Location not set',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(inc.createdAt),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statusChip(inc.status),
                            if (inc.assignedUnitId != null) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.local_shipping,
                                size: 12,
                                color: AppColors.enRoute,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                inc.assignedUnitId!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.enRoute,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 20 * i)).fadeIn();
        },
      ),
    );
  }

  Widget _statusChip(IncidentStatus s) {
    final color = s.isActive
        ? AppColors.enRoute
        : (s == IncidentStatus.resolved
              ? AppColors.available
              : AppColors.outOfService);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        s.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _severityBadge(IncidentSeverity s, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        s.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// =============================================================================
// Incident Detail Panel
// =============================================================================

class _IncidentDetailPanel extends ConsumerStatefulWidget {
  final Incident incident;
  final VoidCallback onClose;

  const _IncidentDetailPanel({required this.incident, required this.onClose});

  @override
  ConsumerState<_IncidentDetailPanel> createState() =>
      _IncidentDetailPanelState();
}

class _IncidentDetailPanelState extends ConsumerState<_IncidentDetailPanel> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final severityColor = _severityColor(incident.severity);
    final fmt = DateFormat('MMM d, yyyy HH:mm');
    final user = ref.watch(currentUserProvider);
    final municipalityId = user?.municipalityId ?? '';

    // Look up the assigned unit so its type (ALS/BLS/MICU/Rescue) can be shown
    // alongside the call sign in the Assignment section.
    final units = municipalityId.isEmpty
        ? const <AmbulanceUnit>[]
        : ref.watch(municipalityUnitsProvider(municipalityId)).value ?? const <AmbulanceUnit>[];
    AmbulanceUnit? assignedUnit;
    if (incident.assignedUnitId != null) {
      for (final u in units) {
        if (u.id == incident.assignedUnitId) {
          assignedUnit = u;
          break;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Incident Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ─ Severity + status
          Row(
            children: [
              _badge(incident.severity.displayName, severityColor),
              const SizedBox(width: 8),
              _badge(
                incident.status.displayName,
                incident.status.isActive
                    ? AppColors.enRoute
                    : AppColors.available,
              ),
              const Spacer(),
              Text(
                incident.incidentType,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─ Description
          Text(
            incident.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // ─ Location
          _section(context, 'Location', Icons.place_outlined, [
            _row('Address', incident.address ?? 'Unknown'),
            if (incident.landmark != null) _row('Landmark', incident.landmark!),
            _row(
              'Coordinates',
              '${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}',
            ),
          ]),
          const SizedBox(height: 12),

          // ─ Reporter
          if (incident.reporterName != null)
            _section(context, 'Reporter', Icons.person_outline, [
              _row('Name', incident.reporterName!),
              if (incident.reporterPhone != null)
                _row('Phone', incident.reporterPhone!),
            ]),
          if (incident.reporterName != null) const SizedBox(height: 12),

          // ─ Assignment
          if (incident.assignedUnitId != null)
            _section(context, 'Assignment', Icons.local_shipping_outlined, [
              _row(
                'Unit',
                incident.assignedUnitCallSign ?? incident.assignedUnitId!,
              ),
              // Ambulance unit type (ALS / BLS / MICU / Rescue).
              if (assignedUnit != null)
                _row('Unit Type', assignedUnit.type.displayName),
              if (incident.assignedDriverName != null)
                _row('Driver', incident.assignedDriverName!),
              if (incident.dispatcherName != null)
                _row('Dispatch Officer', incident.dispatcherName!),
              if (incident.destinationHospitalName != null)
                _row('Destination Hospital', incident.destinationHospitalName!),
            ]),
          if (incident.assignedUnitId != null) const SizedBox(height: 12),

          // ─ Patient
          if (incident.patientName != null)
            _section(context, 'Patient', Icons.personal_injury_outlined, [
              _row('Name', incident.patientName!),
              if (incident.patientAge != null)
                _row('Age', '${incident.patientAge} yrs'),
              if (incident.patientCondition != null)
                _row('Condition', incident.patientCondition!),
              if (incident.triageNotes != null)
                _row('Triage Notes', incident.triageNotes!),
            ]),
          if (incident.patientName != null) const SizedBox(height: 12),

          // ─ Timeline
          _section(context, 'Timeline', Icons.timeline, [
            _row('Created', fmt.format(incident.createdAt)),
            if (incident.acknowledgedAt != null)
              _row('Acknowledged', fmt.format(incident.acknowledgedAt!)),
            if (incident.dispatchedAt != null)
              _row('Dispatched', fmt.format(incident.dispatchedAt!)),
            if (incident.enRouteAt != null)
              _row('En Route', fmt.format(incident.enRouteAt!)),
            if (incident.onSceneAt != null)
              _row('On Scene', fmt.format(incident.onSceneAt!)),
            if (incident.transportingAt != null)
              _row('Transporting', fmt.format(incident.transportingAt!)),
            if (incident.atHospitalAt != null)
              _row('At Hospital', fmt.format(incident.atHospitalAt!)),
            if (incident.resolvedAt != null)
              _row('Resolved', fmt.format(incident.resolvedAt!)),
            if (incident.cancelledAt != null)
              _row('Cancelled', fmt.format(incident.cancelledAt!)),
          ]),

          const SizedBox(height: 20),

          // ─── Action Buttons
          if (municipalityId.isNotEmpty)
            _buildActions(context, incident, municipalityId, user),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    Incident incident,
    String municipalityId,
    User? user,
  ) {
    final items = <Widget>[];

    switch (incident.status) {
      case IncidentStatus.pending:
        items.add(
          FilledButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Acknowledge Incident'),
            onPressed: _loading
                ? null
                : () => _acknowledge(municipalityId, incident, user),
          ),
        );
      case IncidentStatus.acknowledged:
        items.add(
          FilledButton.icon(
            icon: const Icon(Icons.local_shipping),
            label: const Text('Dispatch Unit'),
            onPressed: _loading
                ? null
                : () => _showDispatchDialog(
                    context,
                    municipalityId,
                    incident,
                    user,
                  ),
          ),
        );
      case IncidentStatus.dispatched:
      case IncidentStatus.enRoute:
      case IncidentStatus.onScene:
      case IncidentStatus.transporting:
      case IncidentStatus.atHospital:
        items.add(
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined, color: AppColors.critical),
            label: const Text(
              'Cancel Dispatch',
              style: TextStyle(color: AppColors.critical),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.critical),
            ),
            onPressed: _loading
                ? null
                : () => _cancelDispatch(context, municipalityId, incident),
          ),
        );
      case IncidentStatus.resolved:
      case IncidentStatus.cancelled:
        // Terminal states — no actions
        break;
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Actions',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            ...items,
            // Add Resolve button for active missions with an assigned unit
            if (incident.assignedUnitId != null &&
                incident.status.isActive &&
                incident.status != IncidentStatus.dispatched &&
                incident.status != IncidentStatus.acknowledged &&
                incident.status != IncidentStatus.pending)
              FilledButton.icon(
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Resolve Incident'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.available,
                ),
                onPressed: _loading
                    ? null
                    : () => _resolveIncident(context, municipalityId, incident),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _acknowledge(
    String municipalityId,
    Incident incident,
    User? user,
  ) async {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: municipalityId,
      action: 'acknowledging an incident',
    )) {
      return;
    }
    setState(() => _loading = true);
    try {
      final service = ref.read(dispatchServiceProvider);
      await service.acknowledgeIncident(
        municipalityId: municipalityId,
        incidentId: incident.id,
        dispatcherUid: user?.id ?? '',
        dispatcherName: user?.fullName ?? 'Dispatcher',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident acknowledged'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDispatchDialog(
    BuildContext context,
    String municipalityId,
    Incident incident,
    User? user,
  ) {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: municipalityId,
      action: 'dispatching a unit',
    )) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _DispatchUnitDialog(
        municipalityId: municipalityId,
        incident: incident,
        dispatcherUid: user?.id ?? '',
        dispatcherName: user?.fullName ?? 'Dispatcher',
      ),
    );
  }

  Future<void> _cancelDispatch(
    BuildContext context,
    String municipalityId,
    Incident incident,
  ) async {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: municipalityId,
      action: 'updating an incident',
    )) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Dispatch?'),
        content: const Text(
          'This will free the assigned unit and cancel the incident. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final service = ref.read(dispatchServiceProvider);
      await service.cancelDispatch(
        municipalityId: municipalityId,
        incidentId: incident.id,
        unitId: incident.assignedUnitId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveIncident(
    BuildContext context,
    String municipalityId,
    Incident incident,
  ) async {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: municipalityId,
      action: 'updating an incident',
    )) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident?'),
        content: const Text(
          'Mark this incident as resolved and free the assigned unit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.available),
            child: const Text('Yes, Resolve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final service = ref.read(dispatchServiceProvider);
      await service.resolveIncident(
        municipalityId: municipalityId,
        incidentId: incident.id,
        unitId: incident.assignedUnitId ?? '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident resolved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }
}

// =============================================================================
// Dispatch Unit Dialog
// =============================================================================

class _DispatchUnitDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  final Incident incident;
  final String dispatcherUid;
  final String dispatcherName;

  const _DispatchUnitDialog({
    required this.municipalityId,
    required this.incident,
    required this.dispatcherUid,
    required this.dispatcherName,
  });

  @override
  ConsumerState<_DispatchUnitDialog> createState() =>
      _DispatchUnitDialogState();
}

class _DispatchUnitDialogState extends ConsumerState<_DispatchUnitDialog> {
  AmbulanceUnit? _selectedUnit;

  Future<void> _dispatch() async {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: widget.municipalityId,
      action: 'dispatching a unit',
    )) {
      return;
    }
    if (_selectedUnit == null) return;

    // Warn if unit has no driver
    if (_selectedUnit!.assignedDriverId == null ||
        _selectedUnit!.assignedDriverId!.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Driver Assigned'),
          content: Text(
            '${_selectedUnit!.callSign} has no driver assigned. Dispatch anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Dispatch Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final service = ref.read(dispatchServiceProvider);
    try {
      await service.dispatchUnit(
        municipalityId: widget.municipalityId,
        incidentId: widget.incident.id,
        unitId: _selectedUnit!.id,
        unitCallSign: _selectedUnit!.callSign,
        driverId: _selectedUnit!.assignedDriverId ?? '',
        driverName: _selectedUnit!.assignedDriverName ?? 'No Driver',
        dispatcherUid: widget.dispatcherUid,
        dispatcherName: widget.dispatcherName,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUnit!.callSign} dispatched'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableAsync = ref.watch(
      availableUnitsProvider(widget.municipalityId),
    );

    return AlertDialog(
      title: const Text('Dispatch Unit'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: availableAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text('No Available Units', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      'All units are either busy or out of service.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final incident = widget.incident;
            final hasCoords = incident.latitude != 0 || incident.longitude != 0;
            final options = <_UnitOption>[];

            for (final u in units) {
              double? distKm;
              double? eta;
              if (hasCoords && u.latitude != null && u.longitude != null) {
                distKm = LocationService.distanceInKm(
                  startLatitude: u.latitude!,
                  startLongitude: u.longitude!,
                  endLatitude: incident.latitude,
                  endLongitude: incident.longitude,
                );
                eta = LocationService.estimateTravelTimeMinutes(
                  distanceKm: distKm,
                );
              }
              options.add(
                _UnitOption(unit: u, distanceKm: distKm, etaMinutes: eta),
              );
            }
            options.sort(
              (a, b) => (a.distanceKm ?? double.infinity).compareTo(
                b.distanceKm ?? double.infinity,
              ),
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Units (${options.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a unit to dispatch to this incident',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RadioGroup<String>(
                    groupValue: _selectedUnit?.id,
                    onChanged: (id) {
                      for (final o in options) {
                        if (o.unit.id == id) {
                          setState(() => _selectedUnit = o.unit);
                          break;
                        }
                      }
                    },
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final o = options[i];
                        final u = o.unit;
                        final isSelected = _selectedUnit?.id == u.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedUnit = u),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.municipalAdmin.withValues(
                                      alpha: 0.08,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: AppColors.municipalAdmin)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: u.id,
                                  activeColor: AppColors.municipalAdmin,
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.available.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    size: 16,
                                    color: AppColors.available,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.callSign,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            u.type.displayName,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (u.assignedDriverName != null) ...[
                                            const Text(
                                              ' · ',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              u.assignedDriverName!,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (o.distanceKm != null) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        o.distanceDisplay,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        o.etaDisplay,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading units: $e')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.local_shipping, size: 18),
          label: const Text('Dispatch Now'),
          onPressed: _selectedUnit != null ? _dispatch : null,
        ),
      ],
    );
  }
}

/// Helper model for the dispatch dialog unit display.
class _UnitOption {
  final AmbulanceUnit unit;
  final double? distanceKm;
  final double? etaMinutes;

  const _UnitOption({required this.unit, this.distanceKm, this.etaMinutes});

  String get distanceDisplay {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get etaDisplay {
    if (etaMinutes == null) return '';
    if (etaMinutes! < 1) return '< 1 min';
    return '~${etaMinutes!.round()} min';
  }
}

// =============================================================================
// Manual (on-behalf-of-citizen) Request Dialog
// =============================================================================

/// Lets a municipal admin log an ambulance request that arrived by phone or
/// Facebook chat. The admin types the caller's details and drops a pin on the
/// map to capture the requester's exact lat/lng, then files it as an incident.
class _ManualRequestDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  const _ManualRequestDialog({required this.municipalityId});

  @override
  ConsumerState<_ManualRequestDialog> createState() =>
      _ManualRequestDialogState();
}

class _ManualRequestDialogState extends ConsumerState<_ManualRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _patientAgeCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();

  IncidentSeverity _severity = IncidentSeverity.urgent;

  // Pin dropped on the map — the requester's location.
  LatLng? _pin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Start the pin at the municipality center so the map opens somewhere sane.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final muni = ref.read(municipalityProvider(widget.municipalityId)).value;
      setState(() {
        _pin ??= LatLng(
          muni?.centerLatitude ?? 14.5995,
          muni?.centerLongitude ?? 120.9842,
        );
      });
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _landmarkCtrl,
      _descCtrl,
      _patientCtrl,
      _patientAgeCtrl,
      _conditionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!allowMunicipalityOperation(
      context,
      ref,
      municipalityId: widget.municipalityId,
      action: 'logging a new request',
    )) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drop a pin on the map to set the request location.'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    setState(() => _saving = true);
    try {
      await ref.read(incidentServiceProvider).createAdminIncident(
        dispatcherUid: user?.id ?? '',
        dispatcherName: user?.fullName ?? 'Municipal Admin',
        municipalityId: widget.municipalityId,
        latitude: _pin!.latitude,
        longitude: _pin!.longitude,
        severity: _severity,
        incidentType: 'emergency',
        description: _descCtrl.text.trim(),
        reporterName: _nameCtrl.text.trim().isEmpty
            ? null
            : _nameCtrl.text.trim(),
        reporterPhone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim().isEmpty
            ? null
            : _landmarkCtrl.text.trim(),
        patientName: _patientCtrl.text.trim().isEmpty
            ? null
            : _patientCtrl.text.trim(),
        patientAge: int.tryParse(_patientAgeCtrl.text.trim()),
        patientCondition: _conditionCtrl.text.trim().isEmpty
            ? null
            : _conditionCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request logged and added to the active queue.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muni = ref.watch(municipalityProvider(widget.municipalityId)).value;
    final center = LatLng(
      muni?.centerLatitude ?? 14.5995,
      muni?.centerLongitude ?? 120.9842,
    );

    return Dialog(
      child: SizedBox(
        width: 720,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_call, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'New Citizen Request',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Log a request taken via cellular call or Facebook chat. '
                  'Drop a pin to set the requester location.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left: form fields
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Caller Name',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Caller Phone',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _addressCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _landmarkCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Landmark',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Description *',
                                  isDense: true,
                                ),
                                maxLines: 2,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<IncidentSeverity>(
                                initialValue: _severity,
                                decoration: const InputDecoration(
                                  labelText: 'Severity',
                                  isDense: true,
                                ),
                                items: IncidentSeverity.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.displayName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => _severity = v ?? IncidentSeverity.urgent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _patientCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Patient Name',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: _patientAgeCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Age',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _conditionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Patient Condition',
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // ── Right: map pin picker
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requester Location',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      options: MapOptions(
                                        initialCenter: center,
                                        initialZoom: 13,
                                        onTap: (tapPos, latLng) {
                                          setState(() => _pin = latLng);
                                        },
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.adms.app',
                                        ),
                                        if (_pin != null)
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _pin!,
                                                width: 40,
                                                height: 40,
                                                child: const Icon(
                                                  Icons.location_pin,
                                                  color: AppColors.critical,
                                                  size: 40,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Positioned(
                                      left: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Tap the map to drop the pin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _pin == null
                                  ? 'No location selected'
                                  : 'Lat ${_pin!.latitude.toStringAsFixed(5)}, '
                                        'Lng ${_pin!.longitude.toStringAsFixed(5)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMutedOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Log Request'),
                      onPressed: _saving ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
