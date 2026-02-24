import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';

// =============================================================================
// REPORTS SCREEN  (scaffold — Super Admin only)
// =============================================================================

/// System-wide analytics and reporting screen.
///
/// TODO: Aggregate data from Firebase RTDB incidents, units, and
/// municipalities nodes to populate charts and summary tables.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export report',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date range filter ──────────────────────────────────────
            _DateRangeRow()
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),

            // ── KPI summary cards ──────────────────────────────────────
            Text('Key Metrics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: _kpiItems
                  .asMap()
                  .entries
                  .map((entry) => _KpiCard(item: entry.value)
                      .animate(
                          delay: Duration(milliseconds: 80 * entry.key))
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.08, end: 0))
                  .toList(),
            ),
            const SizedBox(height: 32),

            // ── Incident trend (placeholder chart) ─────────────────────
            Text('Incident Trends',
                    style: Theme.of(context).textTheme.titleLarge)
                .animate(delay: 300.ms)
                .fadeIn(duration: 350.ms),
            const SizedBox(height: 16),
            _ChartPlaceholder(
              icon: Icons.bar_chart_outlined,
              label: 'Incident volume per day/week/month',
              height: 220,
            )
                .animate(delay: 350.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),

            // ── Response time (placeholder chart) ──────────────────────
            Text('Average Response Time',
                    style: Theme.of(context).textTheme.titleLarge)
                .animate(delay: 450.ms)
                .fadeIn(duration: 350.ms),
            const SizedBox(height: 16),
            _ChartPlaceholder(
              icon: Icons.timeline_outlined,
              label: 'Mean response time per municipality (minutes)',
              height: 200,
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 32),

            // ── Coming soon note ───────────────────────────────────────
            Card(
              color: AppColors.secondary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Charts require an analytics library (e.g. fl_chart or '
                        'syncfusion_flutter_charts) wired to aggregated RTDB '
                        'queries. The KPI values above should be driven by '
                        'Riverpod stream/future providers.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// KPI DATA
// =============================================================================

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
}

const _kpiItems = <_KpiItem>[
  _KpiItem(
    label: 'Total Incidents',
    value: '—',
    icon: Icons.warning_amber_outlined,
    color: AppColors.critical,
    trend: 'this month',
  ),
  _KpiItem(
    label: 'Avg Response Time',
    value: '—',
    icon: Icons.timer_outlined,
    color: AppColors.dispatcher,
    trend: 'minutes',
  ),
  _KpiItem(
    label: 'Resolved Incidents',
    value: '—',
    icon: Icons.check_circle_outline,
    color: AppColors.available,
    trend: 'this month',
  ),
  _KpiItem(
    label: 'Active Units',
    value: '—',
    icon: Icons.local_shipping_outlined,
    color: AppColors.driver,
    trend: 'system-wide',
  ),
];

// =============================================================================
// WIDGETS
// =============================================================================

class _DateRangeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        OutlinedButton(
          onPressed: () {},
          child: const Text('Last 30 days'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Custom range'),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  if (item.trend != null)
                    Text(item.trend!,
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

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.icon,
    required this.label,
    required this.height,
  });

  final IconData icon;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
