import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/models.dart';
import '../../core/theme/theme.dart';

// =============================================================================
// DISPATCH MAP WIDGET
// =============================================================================

/// Live dispatch map showing real-time ambulance positions and incident pins.
///
/// Uses [flutter_map] with Mapbox tile layers — works on Web, Android, iOS,
/// and Desktop without a native SDK.
///
/// Requires `MAPBOX_ACCESS_TOKEN` in the project `.env` file (or falls back
/// to an OpenStreetMap tile layer when the token is absent).
class DispatchMapWidget extends StatefulWidget {
  const DispatchMapWidget({
    super.key,
    required this.incidents,
    required this.units,
    this.centerLatitude = 12.8797,
    this.centerLongitude = 121.7740,
    this.initialZoom = 11.0,
    this.onIncidentTap,
    this.onUnitTap,
  });

  final List<Incident> incidents;
  final List<AmbulanceUnit> units;

  /// Default center — Philippines if no municipality center is provided.
  final double centerLatitude;
  final double centerLongitude;
  final double initialZoom;

  final void Function(Incident incident)? onIncidentTap;
  final void Function(AmbulanceUnit unit)? onUnitTap;

  @override
  State<DispatchMapWidget> createState() => _DispatchMapWidgetState();
}

class _DispatchMapWidgetState extends State<DispatchMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tile URL — Mapbox Streets or OSM fallback
  // ---------------------------------------------------------------------------

  String get _tileUrl {
    final token = dotenv.maybeGet('MAPBOX_ACCESS_TOKEN') ??
        dotenv.maybeGet('MAPS_API_KEY');
    if (token != null && token.isNotEmpty && !token.startsWith('your_')) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
    }
    // Fallback to OpenStreetMap Humanitarian layer (free, no token)
    return 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  }

  bool get _usingMapbox {
    final token = dotenv.maybeGet('MAPBOX_ACCESS_TOKEN') ??
        dotenv.maybeGet('MAPS_API_KEY');
    return token != null && token.isNotEmpty && !token.startsWith('your_');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(),
        _buildZoomControls(),
        _buildLegend(context),
        if (!_usingMapbox) _buildOsmNotice(context),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            LatLng(widget.centerLatitude, widget.centerLongitude),
        initialZoom: widget.initialZoom,
        maxZoom: 19.0,
        minZoom: 4.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'com.adms.app',
          tileProvider: NetworkTileProvider(),
        ),

        // ── Incident markers ──────────────────────────────────────────────
        MarkerLayer(
          markers: widget.incidents
              .where((i) => !i.status.isTerminal)
              .map((incident) => Marker(
                    point: LatLng(incident.latitude, incident.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => widget.onIncidentTap?.call(incident),
                      child: _IncidentPin(incident: incident),
                    ),
                  ))
              .toList(),
        ),

        // ── Ambulance unit markers ─────────────────────────────────────────
        MarkerLayer(
          markers: widget.units
              .where((u) =>
                  u.latitude != null &&
                  u.longitude != null &&
                  u.status != UnitStatus.outOfService)
              .map((unit) => Marker(
                    point: LatLng(unit.latitude!, unit.longitude!),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => widget.onUnitTap?.call(unit),
                      child: _UnitMarker(unit: unit),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Overlay widgets
  // ---------------------------------------------------------------------------

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        children: [
          _MapButton(
            heroTag: 'zoom_in',
            icon: Icons.add,
            onTap: () {
              final cam = _mapController.camera;
              _mapController.move(cam.center, cam.zoom + 1);
            },
          ),
          const SizedBox(height: 6),
          _MapButton(
            heroTag: 'zoom_out',
            icon: Icons.remove,
            onTap: () {
              final cam = _mapController.camera;
              _mapController.move(cam.center, cam.zoom - 1);
            },
          ),
          const SizedBox(height: 6),
          _MapButton(
            heroTag: 'center',
            icon: Icons.my_location,
            onTap: () => _mapController.move(
              LatLng(widget.centerLatitude, widget.centerLongitude),
              widget.initialZoom,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 300.ms)
          .slideX(begin: 0.3, end: 0),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final activeIncidents =
        widget.incidents.where((i) => !i.status.isTerminal).length;
    final activeUnits =
        widget.units.where((u) => u.status.isBusy).length;
    final availableUnits =
        widget.units.where((u) => u.status == UnitStatus.available).length;

    return Positioned(
      left: 12,
      bottom: 12,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Live Overview',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _LegendRow(
                  color: AppColors.critical,
                  label: 'Active Incidents',
                  count: activeIncidents),
              _LegendRow(
                  color: AppColors.enRoute,
                  label: 'Units on Mission',
                  count: activeUnits),
              _LegendRow(
                  color: AppColors.available,
                  label: 'Units Available',
                  count: availableUnits),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 300.ms)
          .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildOsmNotice(BuildContext context) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.urgent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Mapbox token not set — using OpenStreetMap fallback. '
            'Add MAPBOX_ACCESS_TOKEN to .env for Mapbox tiles.',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INCIDENT PIN
// =============================================================================

class _IncidentPin extends StatelessWidget {
  const _IncidentPin({required this.incident});
  final Incident incident;

  Color get _color {
    switch (incident.severity) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${incident.severity.displayName} — ${incident.address}\n${incident.status.displayName}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 16),
          ),
          // Pin tail
          CustomPaint(
            size: const Size(10, 8),
            painter: _PinTailPainter(color: _color),
          ),
        ],
      ),
    );
  }
}

/// Draws the triangular tail beneath the pin circle.
class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// =============================================================================
// UNIT MARKER
// =============================================================================

class _UnitMarker extends StatelessWidget {
  const _UnitMarker({required this.unit});
  final AmbulanceUnit unit;

  Color get _color {
    switch (unit.status) {
      case UnitStatus.available:
        return AppColors.available;
      case UnitStatus.enRoute:
        return AppColors.enRoute;
      case UnitStatus.onScene:
        return AppColors.onScene;
      case UnitStatus.transporting:
        return AppColors.transporting;
      case UnitStatus.atHospital:
        return AppColors.atHospital;
      case UnitStatus.outOfService:
        return AppColors.outOfService;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${unit.callSign} — ${unit.type.displayName}\n${unit.status.displayName}',
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: _color.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping,
                color: Colors.white, size: 18),
            Text(
              unit.callSign.length > 6
                  ? unit.callSign.substring(0, 6)
                  : unit.callSign,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL HELPERS
// =============================================================================

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.heroTag,
    required this.icon,
    required this.onTap,
  });

  final String heroTag;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.count});

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: ',
              style: Theme.of(context).textTheme.labelSmall),
          Text('$count',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// =============================================================================
// EXTENSION — helpers used above
// =============================================================================

extension on IncidentStatus {
  bool get isTerminal =>
      this == IncidentStatus.resolved || this == IncidentStatus.cancelled;
}
