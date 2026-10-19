import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen showing all available ambulances in the municipality the citizen is
/// linked to (the same `municipalityId` on their profile).
///
/// Accessible from: Home Quick Services > Ambulance List Available
/// (this screen replaces the old "Nearby Ambulances" map screen).
class AmbulanceListAvailableScreen extends ConsumerWidget {
  const AmbulanceListAvailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final municipalityId = user?.municipalityId?.trim() ?? '';

    if (user == null || municipalityId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ambulance List Available')),
        body: const Center(child: Text('No municipality assigned.')),
      );
    }

    // Scoped to the citizen's own municipality — never other LGUs.
    final unitsAsync = ref.watch(availableUnitsProvider(municipalityId));
    final municipalityAsync = ref.watch(municipalityProvider(municipalityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance List Available'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Municipality banner — makes the scope obvious.
          municipalityAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (muni) => Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.citizen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.citizen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city,
                    color: AppColors.citizen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      muni == null
                          ? 'Your municipality'
                          : 'Available units in ${muni.name}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.citizen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
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
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ambulances available',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All units may be dispatched. Check back later.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.available.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: AppColors.available,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              unit.callSign,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${unit.type.displayName}${unit.assignedDriverName != null ? ' • Driver: ${unit.assignedDriverName}' : ''}',
                            ),
                            trailing: const Chip(
                              label: Text(
                                'Available',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: AppColors.available,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        )
                        .animate(delay: (index * 50).ms)
                        .fadeIn()
                        .slideX(begin: -0.1, end: 0);
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
