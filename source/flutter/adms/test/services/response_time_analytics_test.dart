import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/incident.dart';
import 'package:adms/core/services/response_time_analytics.dart';

void main() {
  group('ResponseTimeAnalytics - Individual Metrics', () {
    final baseTime = DateTime(2025, 6, 15, 10, 0); // 10:00 AM

    Incident createFullIncident() {
      return Incident(
        id: 'inc-1',
        municipalityId: 'mun-1',
        reporterId: 'user-1',
        reporterName: 'Test',
        reporterPhone: '123',
        description: 'Test emergency',
        incidentType: 'cardiac',
        address: 'Test address',
        latitude: 14.5,
        longitude: 120.9,
        severity: IncidentSeverity.critical,
        status: IncidentStatus.resolved,
        createdAt: baseTime,
        dispatchedAt: baseTime.add(const Duration(minutes: 2)),
        onSceneAt: baseTime.add(const Duration(minutes: 9)),
        transportingAt: baseTime.add(const Duration(minutes: 20)),
        atHospitalAt: baseTime.add(const Duration(minutes: 35)),
        resolvedAt: baseTime.add(const Duration(minutes: 50)),
      );
    }

    test('callProcessingMinutes calculates created to dispatched', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.callProcessingMinutes(incident), 2.0);
    });

    test('travelTimeMinutes calculates dispatched to onScene', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.travelTimeMinutes(incident), 7.0);
    });

    test('onSceneTimeMinutes calculates onScene to transporting', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.onSceneTimeMinutes(incident), 11.0);
    });

    test('transportTimeMinutes calculates transporting to atHospital', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.transportTimeMinutes(incident), 15.0);
    });

    test('hospitalTurnaroundMinutes calculates atHospital to resolved', () {
      final incident = createFullIncident();
      expect(
        ResponseTimeAnalytics.hospitalTurnaroundMinutes(incident),
        15.0,
      );
    });

    test('totalResponseTimeMinutes calculates created to atHospital', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.totalResponseTimeMinutes(incident), 35.0);
    });

    test('totalDurationMinutes calculates created to resolved', () {
      final incident = createFullIncident();
      expect(ResponseTimeAnalytics.totalDurationMinutes(incident), 50.0);
    });

    test('returns null when timestamps are missing', () {
      final pending = Incident(
        id: 'inc-2',
        municipalityId: 'mun-1',
        reporterId: 'user-1',
        reporterName: 'Test',
        reporterPhone: '123',
        description: 'Pending incident',
        incidentType: 'trauma',
        address: 'Test',
        latitude: 14.0,
        longitude: 121.0,
        severity: IncidentSeverity.normal,
        status: IncidentStatus.pending,
        createdAt: baseTime,
      );

      expect(ResponseTimeAnalytics.callProcessingMinutes(pending), isNull);
      expect(ResponseTimeAnalytics.travelTimeMinutes(pending), isNull);
      expect(ResponseTimeAnalytics.onSceneTimeMinutes(pending), isNull);
      expect(ResponseTimeAnalytics.transportTimeMinutes(pending), isNull);
      expect(
        ResponseTimeAnalytics.hospitalTurnaroundMinutes(pending),
        isNull,
      );
      expect(
        ResponseTimeAnalytics.totalResponseTimeMinutes(pending),
        isNull,
      );
      expect(ResponseTimeAnalytics.totalDurationMinutes(pending), isNull);
    });
  });

  group('ResponseTimeAnalytics - Aggregate Metrics', () {
    final baseTime = DateTime(2025, 6, 15, 10, 0);

    Incident createResolvedIncident({
      required Duration callProcessing,
      required Duration travel,
      required Duration onScene,
      required Duration transport,
      required Duration turnaround,
    }) {
      final dispatched = baseTime.add(callProcessing);
      final onSceneTime = dispatched.add(travel);
      final transporting = onSceneTime.add(onScene);
      final atHospital = transporting.add(transport);
      final resolved = atHospital.add(turnaround);

      return Incident(
        id: 'inc-${callProcessing.inMinutes}',
        municipalityId: 'mun-1',
        reporterId: 'user-1',
        reporterName: 'Test',
        reporterPhone: '123',
        description: 'Test',
        incidentType: 'trauma',
        address: 'Test',
        latitude: 14.0,
        longitude: 121.0,
        severity: IncidentSeverity.urgent,
        status: IncidentStatus.resolved,
        createdAt: baseTime,
        dispatchedAt: dispatched,
        onSceneAt: onSceneTime,
        transportingAt: transporting,
        atHospitalAt: atHospital,
        resolvedAt: resolved,
      );
    }

    test('computeMetrics calculates averages correctly', () {
      final incidents = [
        createResolvedIncident(
          callProcessing: const Duration(minutes: 2),
          travel: const Duration(minutes: 6),
          onScene: const Duration(minutes: 10),
          transport: const Duration(minutes: 12),
          turnaround: const Duration(minutes: 15),
        ),
        createResolvedIncident(
          callProcessing: const Duration(minutes: 4),
          travel: const Duration(minutes: 10),
          onScene: const Duration(minutes: 8),
          transport: const Duration(minutes: 14),
          turnaround: const Duration(minutes: 20),
        ),
      ];

      final metrics = ResponseTimeAnalytics.computeMetrics(incidents);

      expect(metrics.totalResolvedIncidents, 2);
      expect(metrics.avgCallProcessingMinutes, 3.0); // (2+4)/2
      expect(metrics.avgTravelTimeMinutes, 8.0); // (6+10)/2
      expect(metrics.avgOnSceneMinutes, 9.0); // (10+8)/2
      expect(metrics.avgTransportMinutes, 13.0); // (12+14)/2
    });

    test('computeMetrics calculates compliance rates', () {
      final incidents = [
        // Travel time = 6 min (under 8)
        createResolvedIncident(
          callProcessing: const Duration(minutes: 1),
          travel: const Duration(minutes: 6),
          onScene: const Duration(minutes: 5),
          transport: const Duration(minutes: 5),
          turnaround: const Duration(minutes: 5),
        ),
        // Travel time = 10 min (under 15 but over 8)
        createResolvedIncident(
          callProcessing: const Duration(minutes: 1),
          travel: const Duration(minutes: 10),
          onScene: const Duration(minutes: 5),
          transport: const Duration(minutes: 5),
          turnaround: const Duration(minutes: 5),
        ),
        // Travel time = 20 min (over 15)
        createResolvedIncident(
          callProcessing: const Duration(minutes: 1),
          travel: const Duration(minutes: 20),
          onScene: const Duration(minutes: 5),
          transport: const Duration(minutes: 5),
          turnaround: const Duration(minutes: 5),
        ),
      ];

      final metrics = ResponseTimeAnalytics.computeMetrics(incidents);

      // 1 out of 3 under 8 min
      expect(metrics.complianceRate8Min, closeTo(1 / 3, 0.01));
      // 2 out of 3 under 15 min
      expect(metrics.complianceRate15Min, closeTo(2 / 3, 0.01));
    });

    test('computeMetrics handles empty list', () {
      final metrics = ResponseTimeAnalytics.computeMetrics([]);

      expect(metrics.totalResolvedIncidents, 0);
      expect(metrics.avgCallProcessingMinutes, isNull);
      expect(metrics.avgTravelTimeMinutes, isNull);
      expect(metrics.complianceRate8Min, isNull);
      expect(metrics.p90TotalResponseMinutes, isNull);
    });

    test('computeMetrics excludes non-resolved incidents', () {
      final incidents = [
        Incident(
          id: 'inc-pending',
          municipalityId: 'mun-1',
          reporterId: 'user-1',
          reporterName: 'Test',
          reporterPhone: '123',
          description: 'Pending',
          incidentType: 'trauma',
          address: 'Test',
          latitude: 14.0,
          longitude: 121.0,
          severity: IncidentSeverity.normal,
          status: IncidentStatus.pending,
          createdAt: baseTime,
        ),
      ];

      final metrics = ResponseTimeAnalytics.computeMetrics(incidents);
      expect(metrics.totalResolvedIncidents, 0);
    });
  });

  group('ResponseTimeMetrics formatting', () {
    test('formatMinutes displays value with one decimal', () {
      expect(ResponseTimeMetrics.formatMinutes(4.2), '4.2 min');
      expect(ResponseTimeMetrics.formatMinutes(10.0), '10.0 min');
    });

    test('formatMinutes returns dash for null', () {
      expect(ResponseTimeMetrics.formatMinutes(null), '—');
    });

    test('formatPercent displays as percentage', () {
      expect(ResponseTimeMetrics.formatPercent(0.85), '85.0%');
      expect(ResponseTimeMetrics.formatPercent(1.0), '100.0%');
    });

    test('formatPercent returns dash for null', () {
      expect(ResponseTimeMetrics.formatPercent(null), '—');
    });
  });
}
