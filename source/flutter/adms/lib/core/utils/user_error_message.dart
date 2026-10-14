import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Maps an exception caught during a user-initiated action to a message that is
/// safe and useful to display in the UI.
///
/// The previous behaviour across the app was to render the raw exception, e.g.
/// `Text('Error: $e')`, which surfaces internal implementation detail to end
/// users — database paths, permission rules, provider error codes and stack
/// text. That is poor UX and leaks information about the backend.
///
/// Instead this returns a short, human-readable sentence for the well-known
/// Firebase / platform error codes and a generic fallback for everything else.
/// The original exception is still logged via [debugPrint] so it remains
/// available in the console/debugger for diagnosis; it is simply never shown to
/// the user.
///
/// ```dart
/// } catch (e) {
///   showMessage(userErrorMessage(e));
/// }
/// ```
String userErrorMessage(Object error) {
  final String? mapped = _firebaseAuthMessage(error) ??
      _firebaseDatabaseMessage(error) ??
      _platformMessage(error);

  if (mapped != null) return mapped;

  // Unmapped error: log it for diagnosis, show a generic message.
  debugPrint('Unhandled error (generic message shown to user): $error');
  return 'Something went wrong. Please try again.';
}

String? _firebaseAuthMessage(Object error) {
  if (error is! FirebaseAuthException) return null;
  switch (error.code) {
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact your administrator.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'requires-recent-login':
      return 'Please sign in again to continue.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled. Please contact support.';
    case 'network-request-failed':
      return 'No internet connection. Please check your connection and try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

String? _firebaseDatabaseMessage(Object error) {
  if (error is! FirebaseException) return null;
  switch (error.code) {
    case 'permission-denied':
      return 'You do not have permission to perform this action.';
    case 'unavailable':
      return 'The service is temporarily unavailable. Please try again.';
    case 'network-error':
      return 'No internet connection. Please check your connection and try again.';
    case 'not-found':
      return 'The requested record no longer exists.';
    case 'timeout':
      return 'The request timed out. Please try again.';
    case 'too-large':
      return 'The data being saved is too large.';
    case 'invalid-argument':
      return 'The request was invalid. Please review and try again.';
    default:
      return 'A database error occurred. Please try again.';
  }
}

String? _platformMessage(Object error) {
  if (error is TimeoutException) {
    return 'The request took too long. Please try again.';
  }
  if (error is FormatException) {
    return 'Received an unexpected response. Please try again.';
  }
  if (error is TypeError) {
    return 'Something went wrong while processing the response. Please try again.';
  }
  return null;
}
