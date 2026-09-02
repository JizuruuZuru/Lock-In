import 'package:firebase_auth/firebase_auth.dart';

/// Turns a Firebase auth failure into a sentence a primary-school student can
/// act on.
///
/// Every auth screen used to end its `switch` with `e.message ?? 'Unknown
/// error'`, which put raw Firebase copy in front of a child - "We have blocked
/// all requests from this device due to unusual activity." - and left
/// `network-request-failed`, `user-disabled` and `too-many-requests` unmapped
/// entirely. The generic `catch` was worse: `'Error: $e'` printed a Dart
/// exception into a modal.
///
/// [fallback] is the wording to use when the code is genuinely unrecognised, so
/// each caller can stay in its own voice ("Could not sign you in." vs "Could
/// not create the account.").
String authErrorMessage(Object error, {required String fallback}) {
  if (error is! FirebaseAuthException) return fallback;

  return switch (error.code) {
    'user-not-found' || 'invalid-credential' || 'wrong-password' =>
      'No account matched that name and password. Create an account first or '
          'check your spelling.',
    'email-already-in-use' =>
      'An account already uses that first and last name. Try a different '
          'spelling or add a middle initial.',
    'invalid-email' =>
      'That name cannot be turned into a valid login id. Check the spelling.',
    'weak-password' => 'Password is too weak. Use at least 6 characters.',
    'user-disabled' =>
      'This account has been turned off by a teacher. Please ask them to turn '
          'it back on.',
    'too-many-requests' =>
      'Too many tries in a row. Wait a minute, then try again.',
    'network-request-failed' =>
      'No internet connection. Check your Wi-Fi and try again.',
    'operation-not-allowed' =>
      'This way of signing in is turned off. Please tell your teacher.',
    'requires-recent-login' =>
      'Please sign in again before making this change.',
    _ => fallback,
  };
}
