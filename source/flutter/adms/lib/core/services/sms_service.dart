import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Semaphore SMS service provider.
final smsServiceProvider = Provider<SemaphoreSmsService>((ref) {
  return SemaphoreSmsService();
});

// =============================================================================
// SEMAPHORE SMS SERVICE
// =============================================================================

/// Sends SMS alerts through the [Semaphore](https://semaphoreapi.com) SMS API.
///
/// Endpoint (API v3):
/// `GET https://semaphoreapi.com/api/v3/messages.json`
///   - `apikey`   — the Super Admin's Semaphore key (stored in /systemConfig)
///   - `number`   — recipient, e.g. `09171234567` or `+639171234567`
///   - `message`  — message body (GSM-7; keep it ASCII for cheapest billing)
///   - `sendername` — optional registered sender name (max 11 chars)
///
/// The key and sender name are configured in System Settings → Notifications
/// and persisted to RTDB `/systemConfig`, so they are never compiled into the
/// app binary.
class SemaphoreSmsService {
  SemaphoreSmsService({http.Client? client}) : _client = client ?? http.Client();

  static const String endpoint =
      'https://semaphoreapi.com/api/v3/messages.json';

  final http.Client _client;

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Send one SMS using the credentials from [config].
  ///
  /// Returns `true` when Semaphore accepted the message. Returns `false`
  /// (never throws) when SMS is disabled, no API key is configured, the
  /// request fails, or Semaphore reports an error — SMS must never break the
  /// primary (FCM/in-app) notification flow.
  Future<bool> sendSms({
    required SystemConfig config,
    required String number,
    required String message,
  }) async {
    final recipients = await sendToNumbers(
      config: config,
      numbers: [number],
      message: message,
    );
    return recipients;
  }

  /// Send the same SMS to several recipients at once.
  Future<bool> sendToNumbers({
    required SystemConfig config,
    required List<String> numbers,
    required String message,
  }) async {
    if (!config.smsAlertsEnabled) return false;
    final apiKey = config.smsApiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) return false;

    var anyAccepted = false;
    for (final number in numbers) {
      final trimmed = number.trim();
      if (trimmed.isEmpty) continue;
      final ok = await _sendOnce(
        apiKey: apiKey,
        number: trimmed,
        message: message,
        senderName: config.smsSenderName?.trim(),
      );
      anyAccepted = anyAccepted || ok;
    }
    return anyAccepted;
  }

  // ===========================================================================
  // HTTP
  // ===========================================================================

  Future<bool> _sendOnce({
    required String apiKey,
    required String number,
    required String message,
    String? senderName,
  }) async {
    try {
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          'apikey': apiKey,
          'number': number,
          'message': message,
          if (senderName != null && senderName.isNotEmpty)
            'sendername': senderName,
        },
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Semaphore SMS error: HTTP ${response.statusCode} '
          '${response.body}',
        );
        return false;
      }

      // Semaphore replies {"status":"success","count":1,"recipients":[...]}.
      return response.body.contains('"success"');
    } catch (e) {
      debugPrint('Semaphore SMS send failed (non-fatal): $e');
      return false;
    }
  }
}

// =============================================================================
// CONVENIENCE
// =============================================================================

/// Fire-and-forget helper: sends an SMS alert if SMS is enabled in
/// [config], swallowing every error so callers never need a try/catch.
Future<void> sendSmsAlertSilently({
  required WidgetRef ref,
  required SystemConfig config,
  required String number,
  required String message,
}) async {
  try {
    await ref
        .read(smsServiceProvider)
        .sendSms(config: config, number: number, message: message);
  } catch (e) {
    debugPrint('SMS alert failed (non-fatal): $e');
  }
}
