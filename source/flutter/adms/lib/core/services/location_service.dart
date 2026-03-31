import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'unit_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Location service provider.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Stream of the device's current position (updates in real-time).
final positionStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.watchPosition();
});

/// Current position as a one-shot future.
final currentPositionProvider = FutureProvider<Position?>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentPosition();
});

/// Whether location services are available and permitted.
final locationAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.isLocationAvailable();
});

// =============================================================================
// LOCATION SERVICE
// =============================================================================

/// Service for managing device GPS location.
///
/// Used by driver/crew apps to share real-time ambulance position with dispatch.
/// Also used by citizen apps to auto-fill incident location.
class LocationService {
  // ===========================================================================
  // PERMISSIONS & AVAILABILITY
  // ===========================================================================

  /// Check if location services are enabled and permissions granted.
  Future<bool> isLocationAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permissions from the user.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ===========================================================================
  // POSITION TRACKING
  // ===========================================================================

  /// Get the current device position (one-shot).
  Future<Position?> getCurrentPosition() async {
    final available = await isLocationAvailable();
    if (!available) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Stream of position updates for real-time tracking.
  ///
  /// Updates approximately every 10 seconds or when the device moves 10+ meters.
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance (meters) before update
      ),
    );
  }

  // ===========================================================================
  // DISTANCE CALCULATIONS
  // ===========================================================================

  /// Calculate distance in meters between two coordinates.
  static double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate distance in kilometers between two coordinates.
  static double distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return distanceBetween(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    ) / 1000.0;
  }

  /// Estimate travel time in minutes based on straight-line distance.
  /// Uses an average ambulance speed with emergency lights.
  static double estimateTravelTimeMinutes({
    required double distanceKm,
    double averageSpeedKmh = 50.0, // Average with lights & sirens
  }) {
    if (distanceKm <= 0) return 0;
    return (distanceKm / averageSpeedKmh) * 60.0;
  }
}

// =============================================================================
// DRIVER LOCATION TRACKER
// =============================================================================

/// Automatically pushes driver GPS location to Firebase RTDB.
///
/// Start this when a driver logs in with an assigned unit.
/// Stop when the driver logs out or goes off duty.
class DriverLocationTracker {
  final LocationService _locationService;
  final UnitService _unitService;
  StreamSubscription<Position>? _subscription;

  DriverLocationTracker({
    required LocationService locationService,
    required UnitService unitService,
  })  : _locationService = locationService,
        _unitService = unitService;

  bool get isTracking => _subscription != null;

  /// Start broadcasting location to Firebase for the given unit.
  Future<void> startTracking({
    required String municipalityId,
    required String unitId,
  }) async {
    await stopTracking();

    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) return;

    _subscription = _locationService.watchPosition().listen(
      (position) {
        _unitService.updateLocation(
          municipalityId: municipalityId,
          unitId: unitId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      onError: (_) {
        // Silently handle location errors — GPS may temporarily lose signal
      },
    );
  }

  /// Stop broadcasting location.
  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

/// Provider for the driver location tracker.
final driverLocationTrackerProvider = Provider<DriverLocationTracker>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final unitService = ref.watch(unitServiceProvider);
  return DriverLocationTracker(
    locationService: locationService,
    unitService: unitService,
  );
});
