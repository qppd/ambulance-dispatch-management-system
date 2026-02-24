import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

// =============================================================================
// REPORTS SCREEN  — Super Admin, wired to Firebase RTDB
// =============================================================================

/// System-wide analytics screen.
///
/// Streams all incidents via [allIncidentsSystemWideProvider] and all
/// units via [_allUnitsSystemWideProvider] defined below, then computes
/// KPIs and chart data client-side.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// Filter window in days (30 or 90).
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(allIncidentsSystemWideProvider);
    final unitsAsync = ref.watch(_allUnitsSystemWideProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(allIncidentsSystemWideProvider);
              ref.invalidate(_allUnitsSystemWideProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.critical))),
        data: (incidents) {
          final units = unitsAsync.valueOrNull ?? [];
          return _buildContent(context, incidents, units);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Incident> allIncidents,
    List<AmbulanceUnit> allUnits,
  ) {
    // ── Apply date window filter ──────────────────────────────────────────
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    final incidents =
        allIncidents.where((i) => i.createdAt.isAfter(cutoff)).toList();

    // ── KPI computations ─────────────────────────────────────────────────
    final totalIncidents = incidents.length;
    final resolved =
        incidents.where((i) => i.status == IncidentStatus.resolved).length;
    final critical =
        incidents.where((i) => i.severity == IncidentSeverity.critical).length;
    final avgResponseMinutes = _computeAvgResponseMinutes(incidents);
    final activeUnits =
        allUnits.where((u) => u.status.isBusy).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date range selector ─────────────────────────────────────
          _buildDateRangeRow(context),
          const SizedBox(height: 24),

          // ── KPI Cards ──────────────────────────────────────────────
          Text('Key Metrics (last $_rangeDays days)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildKpiGrid(context,
              total: totalIncidents,
              resolved: resolved,
              critical: critical,
              avgResponseMinutes: avgResponseMinutes,
              activeUnits: activeUnits),
          const SizedBox(height: 32),

          // ── Incident trend — bar chart ─────────────────────────────
          Text('Incidents per Day (last 7 days)',
                  style: Theme.of(context).textTheme.titleLarge)
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 16),
          _IncidentTrendChart(incidents: incidents)
              .animate(delay: 350.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 32),

          // ── Severity breakdown — pie chart ─────────────────────────
          Text('Severity Breakdown',
                  style: Theme.of(context).textTheme.titleLarge)
              .animate(delay: 450.ms)
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 16),
          _SeverityPieChart(incidents: incidents)
              .animate(delay: 500.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 32),

          // ── Status breakdown table ─────────────────────────────────
          Text('Incident Status Summary',
                  style: Theme.of(context).textTheme.titleLarge)
              .animate(delay: 560.ms)
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 16),
          _StatusSummaryTable(incidents: incidents)
              .animate(delay: 600.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // ── Response time per municipality ─────────────────────────
          Text('Avg Response Time by Municipality',
                  style: Theme.of(context).textTheme.titleLarge)
              .animate(delay: 660.ms)
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 16),
          _ResponseTimeChart(incidents: incidents)
              .animate(delay: 700.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date range selector
  // ---------------------------------------------------------------------------

  Widget _buildDateRangeRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.date_range_outlined,
            color: AppColors.textMuted, size: 20),
        const SizedBox(width: 8),
        Text('Date Range:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        _RangeButton(
            label: 'Last 30 days',
            selected: _rangeDays == 30,
            onTap: () => setState(() => _rangeDays = 30)),
        const SizedBox(width: 8),
        _RangeButton(
            label: 'Last 90 days',
            selected: _rangeDays == 90,
            onTap: () => setState(() => _rangeDays = 90)),
      ],
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ---------------------------------------------------------------------------
  // KPI grid
  // ---------------------------------------------------------------------------

  Widget _buildKpiGrid(
    BuildContext context, {
    required int total,
    required int resolved,
    required int critical,
    required double avgResponseMinutes,
    required int activeUnits,
  }) {
    final respLabel = avgResponseMinutes < 0
        ? '—'
        : '${avgResponseMinutes.toStringAsFixed(1)} min';

    final items = [
      _KpiData(
          label: 'Total Incidents',
          value: '$total',
          icon: Icons.warning_amber_outlined,
          color: AppColors.critical,
          sub: 'in range'),
      _KpiData(
          label: 'Avg Response Time',
          value: respLabel,
          icon: Icons.timer_outlined,
          color: AppColors.dispatcher,
          sub: 'pending → en route'),
      _KpiData(
          label: 'Resolved',
          value: '$resolved',
          icon: Icons.check_circle_outline,
          color: AppColors.available,
          sub: total > 0
              ? '${(resolved / total * 100).toStringAsFixed(0)}% of total'
              : '—'),
      _KpiData(
          label: 'Critical Incidents',
          value: '$critical',
          icon: Icons.local_fire_department_outlined,
          color: AppColors.critical,
          sub: total > 0
              ? '${(critical / total * 100).toStringAsFixed(0)}% of total'
              : '—'),
      _KpiData(
          label: 'Units on Mission',
          value: '$activeUnits',
          icon: Icons.local_shipping_outlined,
          color: AppColors.driver,
          sub: 'system-wide now'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: items
          .asMap()
          .entries
          .map((e) => _KpiCard(data: e.value)
              .animate(delay: Duration(milliseconds: 70 * e.key))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.08, end: 0))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Average response time helper
  // ---------------------------------------------------------------------------

  double _computeAvgResponseMinutes(List<Incident> incidents) {
    final withResponse = incidents.where((i) => i.enRouteAt != null).toList();
    if (withResponse.isEmpty) return -1;
    final totalMinutes = withResponse.fold<double>(
      0,
      (sum, i) =>
          sum + i.enRouteAt!.difference(i.createdAt).inSeconds / 60.0,
    );
    return totalMinutes / withResponse.length;
  }
}

// =============================================================================
// PROVIDER — all units system-wide
// =============================================================================

/// Streams all ambulance units across all municipalities.
///
/// Reads the top-level `/units` node.
final _allUnitsSystemWideProvider = StreamProvider<List<AmbulanceUnit>>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return dbRef.child('units').onValue.map((event) {
    final allMuni = event.snapshot.value as Map<dynamic, dynamic>?;
    if (allMuni == null) return <AmbulanceUnit>[];
    final result = <AmbulanceUnit>[];
    for (final muniEntry in allMuni.entries) {
      final muniUnits = muniEntry.value as Map<dynamic, dynamic>?;
      if (muniUnits == null) continue;
      for (final unitEntry in muniUnits.entries) {
        try {
          result.add(AmbulanceUnit.fromJson(
              Map<String, dynamic>.from(unitEntry.value as Map)));
        } catch (_) {}
      }
    }
    return result;
  });
});

// =============================================================================
// KPI CARD
// =============================================================================

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  if (data.sub != null)
                    Text(data.sub!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// INCIDENT TREND BAR CHART (last 7 days)
// =============================================================================

class _IncidentTrendChart extends StatelessWidget {
  const _IncidentTrendChart({required this.incidents});
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build a map: dayOffset -> count (0 = today, 6 = 6 days ago)
    final counts = <int, int>{};
    for (var i = 0; i < 7; i++) {
      counts[i] = 0;
    }
    for (final incident in incidents) {
      final diff = now.difference(incident.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        counts[diff] = (counts[diff] ?? 0) + 1;
      }
    }

    final bars = List.generate(7, (i) {
      final dayOffset = 6 - i; // left = 6 days ago, right = today
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (counts[dayOffset] ?? 0).toDouble(),
            color: AppColors.dispatcher,
            width: 20,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
        ],
      );
    });

    final dayLabels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat.E().format(date);
    });

    if (bars.every((b) => b.barRods.first.toY == 0)) {
      return _EmptyChart(
          icon: Icons.bar_chart_outlined,
          label: 'No incidents in the last 7 days');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) =>
                        Text('${v.toInt()}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(dayLabels[v.toInt()],
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: bars,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SEVERITY PIE CHART
// =============================================================================

class _SeverityPieChart extends StatefulWidget {
  const _SeverityPieChart({required this.incidents});
  final List<Incident> incidents;

  @override
  State<_SeverityPieChart> createState() => _SeverityPieChartState();
}

class _SeverityPieChartState extends State<_SeverityPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final critical = widget.incidents
        .where((i) => i.severity == IncidentSeverity.critical)
        .length;
    final urgent = widget.incidents
        .where((i) => i.severity == IncidentSeverity.urgent)
        .length;
    final normal = widget.incidents
        .where((i) => i.severity == IncidentSeverity.normal)
        .length;
    final total = critical + urgent + normal;

    if (total == 0) {
      return _EmptyChart(
          icon: Icons.pie_chart_outline,
          label: 'No incidents in this period');
    }

    final sections = [
      _PieSection(
          value: critical.toDouble(),
          color: AppColors.critical,
          label: 'Critical',
          index: 0),
      _PieSection(
          value: urgent.toDouble(),
          color: AppColors.urgent,
          label: 'Urgent',
          index: 1),
      _PieSection(
          value: normal.toDouble(),
          color: AppColors.available,
          label: 'Normal',
          index: 2),
    ].where((s) => s.value > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (_, response) {
                      setState(() {
                        _touched = response?.touchedSection
                                ?.touchedSectionIndex ??
                            -1;
                      });
                    },
                  ),
                  sections: sections
                      .map((s) => PieChartSectionData(
                            value: s.value,
                            color: s.color,
                            radius: _touched == s.index ? 90 : 80,
                            title:
                                '${(s.value / total * 100).toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ))
                      .toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: sections
                    .map((s) => _LegendItem(
                          color: s.color,
                          label: s.label,
                          count: s.value.toInt(),
                          total: total,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieSection {
  const _PieSection({
    required this.value,
    required this.color,
    required this.label,
    required this.index,
  });
  final double value;
  final Color color;
  final String label;
  final int index;
}

// =============================================================================
// STATUS SUMMARY TABLE
// =============================================================================

class _StatusSummaryTable extends StatelessWidget {
  const _StatusSummaryTable({required this.incidents});
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    final counts = <IncidentStatus, int>{};
    for (final i in incidents) {
      counts[i.status] = (counts[i.status] ?? 0) + 1;
    }
    final sorted = IncidentStatus.values
        .where((s) => counts.containsKey(s))
        .toList();

    if (sorted.isEmpty) {
      return _EmptyChart(
          icon: Icons.list_alt_outlined,
          label: 'No data for selected period');
    }

    return Card(
      child: Column(
        children: sorted.map((s) {
          final count = counts[s] ?? 0;
          final pct = incidents.isNotEmpty
              ? count / incidents.length
              : 0.0;
          return ListTile(
            dense: true,
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _statusColor(s),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(s.displayName,
                style: const TextStyle(fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    color: _statusColor(s),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text('$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statusColor(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.pending:
        return AppColors.urgent;
      case IncidentStatus.acknowledged:
        return AppColors.primary;
      case IncidentStatus.dispatched:
      case IncidentStatus.enRoute:
        return AppColors.enRoute;
      case IncidentStatus.onScene:
        return AppColors.onScene;
      case IncidentStatus.transporting:
        return AppColors.transporting;
      case IncidentStatus.atHospital:
        return AppColors.atHospital;
      case IncidentStatus.resolved:
        return AppColors.available;
      case IncidentStatus.cancelled:
        return AppColors.outOfService;
    }
  }
}

// =============================================================================
// RESPONSE TIME PER MUNICIPALITY — horizontal bar chart
// =============================================================================

class _ResponseTimeChart extends StatelessWidget {
  const _ResponseTimeChart({required this.incidents});
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    // Aggregate response times per municipality
    final muniTotals = <String, double>{};
    final muniCounts = <String, int>{};
    for (final i in incidents) {
      if (i.enRouteAt != null) {
        final mins =
            i.enRouteAt!.difference(i.createdAt).inSeconds / 60.0;
        final muni = i.municipalityId;
        muniTotals[muni] = (muniTotals[muni] ?? 0) + mins;
        muniCounts[muni] = (muniCounts[muni] ?? 0) + 1;
      }
    }
    if (muniTotals.isEmpty) {
      return _EmptyChart(
          icon: Icons.timeline_outlined,
          label: 'No response time data — incidents must reach "En Route" status');
    }

    final avgs = muniTotals.entries.map((e) {
      final avg = e.value / (muniCounts[e.key] ?? 1);
      return _MuniAvg(e.key, avg);
    }).toList()
      ..sort((a, b) => a.avg.compareTo(b.avg));

    final bars = avgs.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.avg,
            color: e.value.avg > 10 ? AppColors.critical : AppColors.available,
            width: 18,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= avgs.length) {
                            return const SizedBox.shrink();
                          }
                          final id = avgs[idx].municipalityId;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                id.length > 8
                                    ? id.substring(0, 8)
                                    : id,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMuted)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('min',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: bars,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '* Threshold line at 10 min. Red bars exceed response time target.',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuniAvg {
  const _MuniAvg(this.municipalityId, this.avg);
  final String municipalityId;
  final double avg;
}

// =============================================================================
// SMALL HELPERS
// =============================================================================

class _RangeButton extends StatelessWidget {
  const _RangeButton(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(onPressed: onTap, child: Text(label))
        : OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.color,
      required this.label,
      required this.count,
      required this.total});
  final Color color;
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label — $count ($pct%)',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}