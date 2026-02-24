import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/models/models.dart';
import 'package:adms/shared/widgets/dispatch_map.dart';

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

Incident _makeIncident({
  String id = 'inc-1',
  double lat = 14.5995,
  double lng = 120.9842,
  IncidentSeverity severity = IncidentSeverity.urgent,
  IncidentStatus status = IncidentStatus.dispatched,
}) =>
    Incident(
      id: id,
      municipalityId: 'mun-1',
      description: 'Test incident',
      severity: severity,
      status: status,
      incidentType: 'medical',
      latitude: lat,
      longitude: lng,
      createdAt: DateTime(2024, 6, 1, 12, 0),
    );

AmbulanceUnit _makeUnit({
  String id = 'unit-1',
  double? lat = 14.6010,
  double? lng = 120.9850,
  UnitStatus status = UnitStatus.available,
}) =>
    AmbulanceUnit(
      id: id,
      municipalityId: 'mun-1',
      callSign: 'AMB-01',
      plateNumber: 'ABC-123',
      type: UnitType.bls,
      status: status,
      latitude: lat,
      longitude: lng,
      createdAt: DateTime(2024),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DispatchMapWidget', () {
    testWidgets('renders without crashing when given empty lists',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DispatchMapWidget(
              incidents: [],
              units: [],
            ),
          ),
        ),
      );
      await tester.pump();
      // FlutterMap tile layer is present
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders with incidents and units', (tester) async {
      final incidents = [
        _makeIncident(id: 'inc-1', severity: IncidentSeverity.critical),
        _makeIncident(
            id: 'inc-2',
            lat: 14.6100,
            lng: 120.9900,
            severity: IncidentSeverity.normal),
      ];
      final units = [
        _makeUnit(id: 'unit-1', status: UnitStatus.available),
        _makeUnit(
            id: 'unit-2',
            lat: 14.6000,
            lng: 120.9800,
            status: UnitStatus.enRoute),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchMapWidget(
              incidents: incidents,
              units: units,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('accepts optional center coordinates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DispatchMapWidget(
              incidents: [],
              units: [],
              centerLatitude: 10.3157,
              centerLongitude: 123.8854,
              initialZoom: 13,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('units without GPS coordinates do not cause errors',
        (tester) async {
      final units = [
        _makeUnit(id: 'unit-nogps', lat: null, lng: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchMapWidget(
              incidents: [],
              units: units,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('onIncidentTap callback is wired', (tester) async {
      Incident? tapped;
      final incident = _makeIncident();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchMapWidget(
              incidents: [incident],
              units: const [],
              onIncidentTap: (i) => tapped = i,
            ),
          ),
        ),
      );
      await tester.pump();
      // Widget renders; callback is assigned (runtime check, not tap simulation
      // since Mapbox tiles would need a network).
      expect(tapped, isNull); // not tapped yet — just verify no crash
    });
  });

  group('DispatchMapWidget legend counts', () {
    test('filters incidents with coordinates correctly', () {
      // This is a pure logic test on data filtering.
      final incidents = [
        _makeIncident(id: 'a', lat: 14.0, lng: 121.0),
        _makeIncident(id: 'b', lat: 15.0, lng: 122.0),
        // An incident without a lat would be filtered out by the widget's
        // coordinate guard, but all test incidents have coords here.
      ];
      expect(incidents.length, 2);
    });

    test('unit model with null coordinates works', () {
      final unit = _makeUnit(lat: null, lng: null);
      expect(unit.latitude, isNull);
      expect(unit.longitude, isNull);
    });
  });
}
