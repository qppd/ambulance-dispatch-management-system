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

/// Whether a municipality is currently active — **call from `build` only**.
///
/// This deliberately uses `ref.watch`: calling it in a screen's `build` both
/// renders the current status AND keeps the municipality stream subscribed for
/// as long as that screen is mounted. That subscription is what lets
/// [allowMunicipalityOperation] / [allowCitizenAmbulanceRequest] read a fresh
/// value from a tap handler — without it the provider would have no listeners,
/// `.value` would be `null`, and the gate would silently fail open.
///
/// A record that has not resolved yet (`null`) is treated as active, so a slow
/// or failed stream never blocks legitimate work — the same fail-open stance
/// the auth layer takes for transient reads.
///
/// Do NOT call this outside `build`: Riverpod refuses `watch` in event
/// handlers. Use [allowMunicipalityOperation] there instead.
bool isMunicipalityActive(WidgetRef ref, String? municipalityId) =>
    _isActive(ref, municipalityId, subscribe: true);

/// Shared implementation behind the public guards above.
bool _isActive(
  WidgetRef ref,
  String? municipalityId, {
  required bool subscribe,
}) {
  final id = municipalityId?.trim() ?? '';
  if (id.isEmpty) return true;
  final async = subscribe
      ? ref.watch(municipalityProvider(id))
      : ref.read(municipalityProvider(id));
  final municipality = async.value;
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
  if (_isActive(ref, municipalityId, subscribe: false)) return true;

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

/// Blocks an ambulance request while the citizen's municipality is deactivated.
///
/// Citizens keep read access to their account (they can still browse the app,
/// track past incidents and manage their profile) — what a deactivation takes
/// away is the ability to file a NEW request. Call this from `build` to drive
/// the disabled button state, and again when the request is actually
/// submitted so a record deactivated while the dialog was open is still
/// refused at the moment of the write.
bool allowCitizenAmbulanceRequest(
  BuildContext context,
  WidgetRef ref,
  String? municipalityId,
) {
  if (_isActive(ref, municipalityId, subscribe: false)) return true;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        'Your municipality is currently deactivated, so ambulance requests '
        'are unavailable. Please call 911 or contact your local government '
        'unit.',
      ),
      backgroundColor: AppColors.critical,
      behavior: SnackBarBehavior.floating,
    ),
  );
  return false;
}
