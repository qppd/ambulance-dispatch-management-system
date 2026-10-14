import 'dart:async';

import 'package:adms/core/utils/user_error_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// G6/G7 regression: user-facing error text must never expose raw exception
/// internals (database paths, provider codes, stack text). All well-known
/// Firebase/platform failures map to a human sentence, and anything unmapped
/// falls back to a generic message while remaining debuggable via debugPrint.
void main() {
  group('userErrorMessage', () {
    test('maps Firebase Database permission-denied to a friendly sentence', () {
      final message = userErrorMessage(
        FirebaseException(plugin: 'firebase_database', code: 'permission-denied'),
      );
      expect(message, isNotEmpty);
      expect(message, isNot(contains('permission-denied')));
      expect(message.toLowerCase(), contains('permission'));
    });

    test('maps Firebase Database network failure to a friendly sentence', () {
      final message = userErrorMessage(
        FirebaseException(plugin: 'firebase_database', code: 'network-error'),
      );
      expect(message.toLowerCase(), contains('connection'));
    });

    test('maps unknown database codes without leaking the code', () {
      final message = userErrorMessage(
        FirebaseException(plugin: 'firebase_database', code: 'weird-internal-code'),
      );
      expect(message, isNot(contains('weird-internal-code')));
      expect(message, isNotEmpty);
    });

    test('maps Firebase Auth wrong-password', () {
      final message = userErrorMessage(
        FirebaseAuthException(
          code: 'wrong-password',
        ),
      );
      expect(message.toLowerCase(), contains('password'));
    });

    test('maps Firebase Auth email-already-in-use', () {
      final message = userErrorMessage(
        FirebaseAuthException(
          code: 'email-already-in-use',
        ),
      );
      expect(message.toLowerCase(), contains('already exists'));
    });

    test('maps Firebase Auth network-request-failed', () {
      final message = userErrorMessage(
        FirebaseAuthException(
          code: 'network-request-failed',
        ),
      );
      expect(message.toLowerCase(), contains('connection'));
    });

    test('maps TimeoutException', () {
      final message = userErrorMessage(
        TimeoutException('slow', const Duration(seconds: 30)),
      );
      expect(message.toLowerCase(), contains('too long'));
    });

    test('falls back to a generic message for unmapped errors', () {
      final message = userErrorMessage(StateError('some internal invariant'));
      expect(message, isNotEmpty);
      // Must not leak the original exception text.
      expect(message, isNot(contains('some internal invariant')));
      expect(message, isNot(contains('Bad state')));
    });

    test('never returns the raw toString() for any mapped input', () {
      final inputs = <Object>[
        FirebaseException(plugin: 'firebase_database', code: 'unavailable'),
        FirebaseAuthException(code: 'user-disabled'),
        FormatException('bad json'),
        Exception('plain exception'),
      ];
      for (final input in inputs) {
        final message = userErrorMessage(input);
        expect(message, isNotEmpty);
        expect(message, isNot(contains(input.toString())));
      }
    });
  });
}
