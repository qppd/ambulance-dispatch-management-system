import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Analytics screen — incident charts, unit utilization, response metrics.
class AnalyticsScreen extends ConsumerWidget {
  final String municipalityId;

  const AnalyticsScreen({required this.municipalityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(allMunicipalityIncidentsProvider(municipalityId));
    final unitsAsync = ref.watch(municipalityUnitsProvider(municipalityId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('Incident trends, unit utilization, and response performance', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),

          incidentsAsync.when(
            data: (incidents) => _AnalyticsContent(incidents: incidents, units: unitsAsync.valueOrNull ?? []),
            loading: () => const Center(child: Padding(padding: EdgeInsets.only(top: 60), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.critical))),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final List<Incident> incidents;
  final List<AmbulanceUnit> units;

  const _AnalyticsContent({required this.incidents, required this.units});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── KPI Cards
        _KpiRow(incidents: incidents, units: units),
        const SizedBox(height: 24),

        // ─── Daily volume + Severity pie
        LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth > 760;
          final bar = _DailyVolumeChart(incidents: incidents);
          final pie = _SeverityPieChart(incidents: incidents);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: bar),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: pie),
                ])
              : Column(children: [bar, const SizedBox(height: 20), pie]);
        }),
        const SizedBox(height: 20),

        // ─── Status distribution + Type breakdown
        LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth > 760;
          final statusPie = _UnitStatusChart(units: units);
          final typeBar = _IncidentTypeChart(incidents: incidents);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: statusPie),
                  const SizedBox(width: 20),
                  Expanded(child: typeBar),
                ])
              : Column(children: [statusPie, const SizedBox(height: 20), typeBar]);
        }),
        const SizedBox(height: 20),

        // ─── Response times
        _ResponseTimesCard(incidents: incidents),
      ],
    );
  }
}

// =============================================================================
// KPI Row
// =============================================================================

class _KpiRow extends StatelessWidget {
  final List<Incident> incidents;
  final List<AmbulanceUnit> units;

  const _KpiRow({required this.incidents, required this.units});

  @override
  Widget build(BuildContext context) {
    final total = incidents.length;
    final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).toList();
    final active = incidents.where((i) => i.status.isActive).length;

    // avg response time = time from creation to dispatched
    Duration? avgDispatch;
    final withDispatch = resolved.where((i) => i.dispatchedAt != null).toList();
    if (withDispatch.isNotEmpty) {
      final totalMs = withDispatch.fold<int>(0, (sum, i) => sum + i.dispatchedAt!.difference(i.createdAt).inSeconds);
      avgDispatch = Duration(seconds: totalMs ~/ withDispatch.length);
    }

    // resolution rate
    final rateStr = total == 0 ? '—' : '${((resolved.length / total) * 100).round()}%';

    final kpis = [
      _Kpi('Total Incidents', '$total', '', AppColors.primary, Icons.emergency),
      _Kpi('Active Now', '$active', 'in progress', AppColors.critical, Icons.warning_amber_outlined),
      _Kpi('Resolved', '${resolved.length}', 'completed', AppColors.available, Icons.check_circle_outline),
      _Kpi('Resolution Rate', rateStr, 'of all incidents', AppColors.secondary, Icons.analytics_outlined),
      if (avgDispatch != null) _Kpi('Avg Dispatch Time', _fmtDuration(avgDispatch), 'from report', AppColors.enRoute, Icons.timer_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: kpis.length,
      itemBuilder: (ctx, i) {
        final k = kpis[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(k.icon, color: k.color, size: 16),
                  const SizedBox(width: 6),
                  Flexible(child: Text(k.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: k.color)),
                    if (k.sub.isNotEmpty) Text(k.sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn().slideX(begin: 0.05, end: 0);
      },
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}

class _Kpi {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const _Kpi(this.label, this.value, this.sub, this.color, this.icon);
}

// =============================================================================
// Daily Volume Bar Chart (last 14 days)
// =============================================================================

class _DailyVolumeChart extends StatelessWidget {
  final List<Incident> incidents;

  const _DailyVolumeChart({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - i)));

    final counts = {for (final d in days) d: 0};
    for (final inc in incidents) {
      final day = DateTime(inc.createdAt.year, inc.createdAt.month, inc.createdAt.day);
      if (counts.containsKey(day)) {
        counts[day] = counts[day]! + 1;
      }
    }

    final maxY = (counts.values.fold(0, (a, b) => a > b ? a : b) + 2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.bar_chart, size: 18),
              const SizedBox(width: 8),
              Text('Incidents (Last 14 Days)', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) => v == v.roundToDouble() && v > 0
                            ? Text('${v.round()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted))
                            : const SizedBox.shrink(),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < days.length && i % 2 == 0) {
                            return Text(DateFormat('M/d').format(days[i]), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: days.asMap().entries.map((entry) {
                    final v = counts[entry.value]!.toDouble();
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          width: 14,
                          color: AppColors.municipalAdmin,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn();
  }
}

// =============================================================================
// Severity Pie Chart
// =============================================================================

class _SeverityPieChart extends StatefulWidget {
  final List<Incident> incidents;

  const _SeverityPieChart({required this.incidents});

  @override
  State<_SeverityPieChart> createState() => _SeverityPieChartState();
}

class _SeverityPieChartState extends State<_SeverityPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final critical = widget.incidents.where((i) => i.severity == IncidentSeverity.critical).length;
    final urgent = widget.incidents.where((i) => i.severity == IncidentSeverity.urgent).length;
    final normal = widget.incidents.where((i) => i.severity == IncidentSeverity.normal).length;
    final total = widget.incidents.length;

    final sections = total == 0
        ? [PieChartSectionData(value: 1, color: AppColors.border, title: 'No Data', radius: 60)]
        : [
            if (critical > 0) PieChartSectionData(value: critical.toDouble(), color: AppColors.critical, title: '$critical', radius: _touched == 0 ? 66 : 58, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            if (urgent > 0) PieChartSectionData(value: urgent.toDouble(), color: AppColors.urgent, title: '$urgent', radius: _touched == 1 ? 66 : 58, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            if (normal > 0) PieChartSectionData(value: normal.toDouble(), color: AppColors.normal, title: '$normal', radius: _touched == 2 ? 66 : 58, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.pie_chart_outline, size: 18),
              const SizedBox(width: 8),
              Text('Severity Distribution', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.touchedSection != null) {
                          _touched = response!.touchedSection!.touchedSectionIndex;
                        } else {
                          _touched = -1;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _legend('Critical', AppColors.critical, critical, total),
            _legend('Urgent', AppColors.urgent, urgent, total),
            _legend('Normal', AppColors.normal, normal, total),
          ],
        ),
      ),
    ).animate(delay: 250.ms).fadeIn();
  }

  Widget _legend(String label, Color color, int count, int total) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text('$count ($pct%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// =============================================================================
// Unit Status Pie Chart
// =============================================================================

class _UnitStatusChart extends StatefulWidget {
  final List<AmbulanceUnit> units;

  const _UnitStatusChart({required this.units});

  @override
  State<_UnitStatusChart> createState() => _UnitStatusChartState();
}

class _UnitStatusChartState extends State<_UnitStatusChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final colors = {
      UnitStatus.available: AppColors.available,
      UnitStatus.enRoute: AppColors.enRoute,
      UnitStatus.onScene: AppColors.onScene,
      UnitStatus.transporting: AppColors.transporting,
      UnitStatus.atHospital: AppColors.atHospital,
      UnitStatus.outOfService: AppColors.outOfService,
    };

    final counts = {for (final s in UnitStatus.values) s: 0};
    for (final u in widget.units) {
      counts[u.status] = counts[u.status]! + 1;
    }

    final total = widget.units.length;
    final sectionStatuses = UnitStatus.values.where((s) => counts[s]! > 0).toList();
    final sections = total == 0
        ? [PieChartSectionData(value: 1, color: AppColors.border, title: 'No Data', radius: 56)]
        : sectionStatuses.asMap().entries.map((e) {
            final s = e.value;
            final c = colors[s]!;
            return PieChartSectionData(
              value: counts[s]!.toDouble(),
              color: c,
              title: '${counts[s]}',
              radius: _touched == e.key ? 64 : 56,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            );
          }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.local_shipping_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Unit Status Distribution', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() => _touched = response?.touchedSection?.touchedSectionIndex ?? -1);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: UnitStatus.values.where((s) => counts[s]! > 0).map((s) {
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[s], shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${s.displayName}: ${counts[s]}', style: const TextStyle(fontSize: 11)),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn();
  }
}

// =============================================================================
// Incident Type Chart
// =============================================================================

class _IncidentTypeChart extends StatelessWidget {
  final List<Incident> incidents;

  const _IncidentTypeChart({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final inc in incidents) {
      counts[inc.incidentType] = (counts[inc.incidentType] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top8 = sorted.take(8).toList();
    final maxVal = top8.isEmpty ? 1 : top8.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.category_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Incident Types', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 16),
            if (top8.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data', style: TextStyle(color: AppColors.textMuted))))
            else
              ...top8.asMap().entries.map((entry) {
                final e = entry.value;
                final ratio = e.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text(e.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 16,
                          backgroundColor: AppColors.border,
                          color: AppColors.municipalAdmin.withOpacity(0.6 + ratio * 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 28, child: Text('${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ]),
                );
              }),
          ],
        ),
      ),
    ).animate(delay: 350.ms).fadeIn();
  }
}

// =============================================================================
// Response Times Card
// =============================================================================

class _ResponseTimesCard extends StatelessWidget {
  final List<Incident> incidents;

  const _ResponseTimesCard({required this.incidents});

  @override
  Widget build(BuildContext context) {
    Duration? avgAcknowledgeTime;
    Duration? avgDispatchTime;
    Duration? avgOnSceneTime;
    Duration? avgResolutionTime;

    Duration _avg(List<Duration> list) => list.isEmpty ? Duration.zero : Duration(seconds: list.fold(0, (a, b) => a + b.inSeconds) ~/ list.length);

    final withAck = incidents.where((i) => i.acknowledgedAt != null).map((i) => i.acknowledgedAt!.difference(i.createdAt)).toList();
    final withDispatch = incidents.where((i) => i.dispatchedAt != null).map((i) => i.dispatchedAt!.difference(i.createdAt)).toList();
    final withScene = incidents.where((i) => i.onSceneAt != null && i.dispatchedAt != null).map((i) => i.onSceneAt!.difference(i.dispatchedAt!)).toList();
    final withResolved = incidents.where((i) => i.resolvedAt != null).map((i) => i.resolvedAt!.difference(i.createdAt)).toList();

    if (withAck.isNotEmpty) avgAcknowledgeTime = _avg(withAck);
    if (withDispatch.isNotEmpty) avgDispatchTime = _avg(withDispatch);
    if (withScene.isNotEmpty) avgOnSceneTime = _avg(withScene);
    if (withResolved.isNotEmpty) avgResolutionTime = _avg(withResolved);

    String fmtDur(Duration? d) {
      if (d == null) return '—';
      if (d.inSeconds < 60) return '${d.inSeconds}s';
      if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Response Time Metrics', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.0,
              children: [
                _timeCard(context, 'Avg. Acknowledge', fmtDur(avgAcknowledgeTime), AppColors.urgent, Icons.visibility_outlined),
                _timeCard(context, 'Avg. Dispatch', fmtDur(avgDispatchTime), AppColors.enRoute, Icons.send_outlined),
                _timeCard(context, 'Avg. On-Scene', fmtDur(avgOnSceneTime), AppColors.onScene, Icons.place_outlined),
                _timeCard(context, 'Avg. Resolution', fmtDur(avgResolutionTime), AppColors.available, Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _timeCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Flexible(child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)))]),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
