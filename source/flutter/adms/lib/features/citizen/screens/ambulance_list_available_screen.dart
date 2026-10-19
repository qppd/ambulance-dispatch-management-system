import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen showing all available ambulances in the user's municipality.
/// Accessible from: Home Quick Services > Ambulance List Available
class AmbulanceListAvailableScreen extends ConsumerWidget {
  const AmbulanceListAvailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.municipalityId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ambulance List')),
        body: const Center(child: Text('No municipality assigned.')),
      );
    }

    final unitsAsync = ref.watch(
      availableUnitsProvider(user.municipalityId!),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance List Available'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: unitsAsync.when(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
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
                          color: AppColors.available.withValues(alpha: 0.1),
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
                      trailing: Chip(
                        label: const Text(
                          'Available',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppColors.available,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
    );
  }
}
