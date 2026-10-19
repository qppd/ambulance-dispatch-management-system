import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen for viewing nearby ambulances on a map.
/// Accessible from: Home Quick Services > Nearby Ambulances.
class NearbyAmbulancesScreen extends ConsumerStatefulWidget {
  const NearbyAmbulancesScreen({super.key});

  @override
  ConsumerState<NearbyAmbulancesScreen> createState() =>
      _NearbyAmbulancesScreenState();
}

class _NearbyAmbulancesScreenState extends ConsumerState<NearbyAmbulancesScreen> {
  double _myLat = 14.5;
  double _myLng = 121.0;
  bool _loadingLocation = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
  }

  Future<void> _loadMyLocation() async {
    try {
      final svc = ref.read(locationServiceProvider);
      final granted = await svc.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
            _errorMsg = 'Location permission denied.';
          });
        }
        return;
      }
      final pos = await svc.getCurrentPosition();
      if (mounted && pos != null) {
        setState(() {
          _myLat = pos.latitude;
          _myLng = pos.longitude;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.municipalityId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Ambulances')),
        body: const Center(child: Text('No municipality assigned.')),
      );
    }

    final unitsAsync = ref.watch(municipalityUnitsProvider(user.municipalityId!));
    final latLng = LatLng(_myLat, _myLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Ambulances'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.adms.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // User location marker
                          Marker(
                            point: latLng,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          // Ambulance unit markers
                          ...unitsAsync.when(
                            data: (units) => units
                                .where((u) => u.latitude != null && u.longitude != null)
                                .map((unit) => Marker(
                                      point: LatLng(unit.latitude!, unit.longitude!),
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: unit.status == UnitStatus.available
                                              ? AppColors.available
                                              : AppColors.enRoute,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: unitsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(userErrorMessage(e))),
                    data: (units) {
                      if (units.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ambulances nearby',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                              ),
                              if (_errorMsg != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _errorMsg!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: units.length,
                        itemBuilder: (context, index) {
                          final unit = units[index];
                          final distKm = (unit.latitude != null && unit.longitude != null)
                              ? LocationService.distanceInKm(
                                  startLatitude: _myLat,
                                  startLongitude: _myLng,
                                  endLatitude: unit.latitude!,
                                  endLongitude: unit.longitude!,
                                )
                              : null;
                          final distStr = distKm != null
                              ? (distKm < 1
                                  ? ' • ${(distKm * 1000).round()}m away'
                                  : ' • ${distKm.toStringAsFixed(1)} km away')
                              : '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: unit.status == UnitStatus.available
                                      ? AppColors.available.withValues(alpha: 0.1)
                                      : AppColors.enRoute.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: unit.status == UnitStatus.available
                                      ? AppColors.available
                                      : AppColors.enRoute,
                                  size: 24,
                                ),
                              ),
                              title: Text(unit.callSign),
                              subtitle: Text(
                                '${unit.type.displayName} • ${unit.status.displayName}$distStr',
                              ),
                              trailing: unit.status == UnitStatus.available
                                  ? const Chip(
                                      label: Text(
                                        'Available',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: AppColors.available,
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
