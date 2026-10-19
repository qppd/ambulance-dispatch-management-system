import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'municipality_service.dart';

// =============================================================================
// DEACTIVATED-MUNICIPALITY OPERATION GATE
// =============================================================================
//
// A municipality deactivated by the Super Admin does NOT lock its people out
// of their accounts — everyone can still sign in and look around. What it does
// stop is work:
//
//   - citizens        : may not file an ambulance request (see the citizen
//                       home screen, which blocks the request flow directly);
//   - municipal admin : may not acknowledge/dispatch incidents, manage units,
//                       manage staff or save any setting;
//   - drivers         : may not change status, accept dispatch or file ePCR.
//
// [allowMunicipalityOperation] is the single guard those screens call before
// performing a mutation, so the refusal (and the explanation) is identical
// everywhere instead of being re-invented per button.

/// Whether a municipality is currently active.
///
/// Reads the already-open [municipalityProvider] stream rather than issuing a
/// fresh request. A record that has not resolved yet (`null`) is treated as
/// active so a slow or failed stream never blocks legitimate work — the same
/// fail-open stance the auth layer takes for transient reads.
bool isMunicipalityActive(WidgetRef ref, String? municipalityId) {
  final id = municipalityId?.trim() ?? '';
  if (id.isEmpty) return true;
  final municipality = ref.read(municipalityProvider(id)).value;
  if (municipality == null) return true;
  return municipality.isActive;
}

/// Returns `true` when the caller may proceed with a mutation.
///
/// When the municipality is deactivated it shows why the action was refused
/// and returns `false`; callers must then simply return.
///
/// ```dart
/// if (!allowMunicipalityOperation(context, ref, municipalityId: id)) return;
/// await svc.acknowledgeIncident(...);
/// ```
bool allowMunicipalityOperation(
  BuildContext context,
  WidgetRef ref, {
  String? municipalityId,
  String? action,
}) {
  if (isMunicipalityActive(ref, municipalityId)) return true;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'This municipality has been deactivated, so '
        '${action ?? 'that action'} is disabled. '
        'Contact the Super Administrator to re-enable it.',
      ),
      backgroundColor: AppColors.critical,
      behavior: SnackBarBehavior.floating,
    ),
  );
  return false;
}
