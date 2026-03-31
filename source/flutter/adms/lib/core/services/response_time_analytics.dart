import '../models/models.dart';

/// Response time analytics calculations for incident performance tracking.
///
/// Computes all time components described in README § 14:
/// - Call Processing Time (created → dispatched)
/// - Travel Time (dispatched → on scene)
/// - On-Scene Time (on scene → transporting)
/// - Transport Time (transporting → at hospital)
/// - Hospital Turnaround Time (at hospital → resolved)
/// - Total Response Time (created → at hospital)
class ResponseTimeAnalytics {
  // ===========================================================================
  // INDIVIDUAL INCIDENT METRICS
  // ===========================================================================

  /// Call processing time in minutes (created → dispatched).
  static double? callProcessingMinutes(Incident incident) {
    if (incident.dispatchedAt == null) return null;
    return incident.dispatchedAt!
        .difference(incident.createdAt)
        .inSeconds / 60.0;
  }

  /// Travel time in minutes (dispatched → arrived on scene).
  static double? travelTimeMinutes(Incident incident) {
    if (incident.dispatchedAt == null || incident.onSceneAt == null) return null;
    return incident.onSceneAt!
        .difference(incident.dispatchedAt!)
        .inSeconds / 60.0;
  }

  /// On-scene time in minutes (arrived → transporting).
  static double? onSceneTimeMinutes(Incident incident) {
    if (incident.onSceneAt == null || incident.transportingAt == null) {
      return null;
    }
    return incident.transportingAt!
        .difference(incident.onSceneAt!)
        .inSeconds / 60.0;
  }

  /// Transport time in minutes (transporting → at hospital).
  static double? transportTimeMinutes(Incident incident) {
    if (incident.transportingAt == null || incident.atHospitalAt == null) {
      return null;
    }
    return incident.atHospitalAt!
        .difference(incident.transportingAt!)
        .inSeconds / 60.0;
  }

  /// Hospital turnaround time in minutes (at hospital → resolved).
  static double? hospitalTurnaroundMinutes(Incident incident) {
    if (incident.atHospitalAt == null || incident.resolvedAt == null) {
      return null;
    }
    return incident.resolvedAt!
        .difference(incident.atHospitalAt!)
        .inSeconds / 60.0;
  }

  /// Total response time in minutes (created → at hospital).
  static double? totalResponseTimeMinutes(Incident incident) {
    if (incident.atHospitalAt == null) return null;
    return incident.atHospitalAt!
        .difference(incident.createdAt)
        .inSeconds / 60.0;
  }

  /// Total incident duration in minutes (created → resolved/cancelled).
  static double? totalDurationMinutes(Incident incident) {
    final end = incident.resolvedAt ?? incident.cancelledAt;
    if (end == null) return null;
    return end.difference(incident.createdAt).inSeconds / 60.0;
  }

  // ===========================================================================
  // AGGREGATE METRICS
  // ===========================================================================

  /// Compute aggregate response time stats from a list of resolved incidents.
  static ResponseTimeMetrics computeMetrics(List<Incident> incidents) {
    final resolved = incidents
        .where((i) => i.status == IncidentStatus.resolved)
        .toList();

    final callProcessingTimes = <double>[];
    final travelTimes = <double>[];
    final onSceneTimes = <double>[];
    final transportTimes = <double>[];
    final turnaroundTimes = <double>[];
    final totalResponseTimes = <double>[];

    for (final incident in resolved) {
      final cp = callProcessingMinutes(incident);
      final tt = travelTimeMinutes(incident);
      final os = onSceneTimeMinutes(incident);
      final tr = transportTimeMinutes(incident);
      final ht = hospitalTurnaroundMinutes(incident);
      final total = totalResponseTimeMinutes(incident);

      if (cp != null && cp >= 0) callProcessingTimes.add(cp);
      if (tt != null && tt >= 0) travelTimes.add(tt);
      if (os != null && os >= 0) onSceneTimes.add(os);
      if (tr != null && tr >= 0) transportTimes.add(tr);
      if (ht != null && ht >= 0) turnaroundTimes.add(ht);
      if (total != null && total >= 0) totalResponseTimes.add(total);
    }

    return ResponseTimeMetrics(
      totalResolvedIncidents: resolved.length,
      avgCallProcessingMinutes: _average(callProcessingTimes),
      avgTravelTimeMinutes: _average(travelTimes),
      avgOnSceneMinutes: _average(onSceneTimes),
      avgTransportMinutes: _average(transportTimes),
      avgHospitalTurnaroundMinutes: _average(turnaroundTimes),
      avgTotalResponseMinutes: _average(totalResponseTimes),
      p90TotalResponseMinutes: _percentile(totalResponseTimes, 0.9),
      complianceRate8Min: _complianceRate(travelTimes, 8.0),
      complianceRate15Min: _complianceRate(travelTimes, 15.0),
    );
  }

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _percentile(List<double> values, double p) {
    if (values.isEmpty) return null;
    final sorted = List<double>.from(values)..sort();
    final index = (p * (sorted.length - 1)).round();
    return sorted[index];
  }

  /// Percentage of travel times under the target (0.0 – 1.0).
  static double? _complianceRate(List<double> times, double targetMinutes) {
    if (times.isEmpty) return null;
    final compliant = times.where((t) => t <= targetMinutes).length;
    return compliant / times.length;
  }
}

// =============================================================================
// RESPONSE TIME METRICS MODEL
// =============================================================================

/// Aggregate response time statistics computed from a set of incidents.
class ResponseTimeMetrics {
  final int totalResolvedIncidents;
  final double? avgCallProcessingMinutes;
  final double? avgTravelTimeMinutes;
  final double? avgOnSceneMinutes;
  final double? avgTransportMinutes;
  final double? avgHospitalTurnaroundMinutes;
  final double? avgTotalResponseMinutes;
  final double? p90TotalResponseMinutes;

  /// Percentage of travel times under 8 minutes (urban target).
  final double? complianceRate8Min;

  /// Percentage of travel times under 15 minutes (rural target).
  final double? complianceRate15Min;

  const ResponseTimeMetrics({
    required this.totalResolvedIncidents,
    this.avgCallProcessingMinutes,
    this.avgTravelTimeMinutes,
    this.avgOnSceneMinutes,
    this.avgTransportMinutes,
    this.avgHospitalTurnaroundMinutes,
    this.avgTotalResponseMinutes,
    this.p90TotalResponseMinutes,
    this.complianceRate8Min,
    this.complianceRate15Min,
  });

  /// Format a nullable double as a display string (e.g. "4.2 min").
  static String formatMinutes(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} min';
  }

  /// Format a nullable percentage (0.0–1.0) as "85.0%".
  static String formatPercent(double? value) {
    if (value == null) return '—';
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
