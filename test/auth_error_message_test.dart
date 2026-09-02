import 'package:benchmark/utils/auth_error_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// The auth screens used to end their switch with `e.message ?? 'Unknown
/// error'`, putting raw Firebase copy in front of a child - and the generic
/// catch printed a Dart exception `toString()` into a modal.
void main() {
  FirebaseAuthException err(String code, [String? message]) =>
      FirebaseAuthException(code: code, message: message);

  test('the three "wrong details" codes collapse to one message, so the app '
      'never reveals whether an account exists', () {
    final messages = {
      for (final code in ['user-not-found', 'invalid-credential', 'wrong-password'])
        authErrorMessage(err(code), fallback: 'x'),
    };
    expect(messages.length, 1);
  });

  test('codes that used to fall through are now mapped', () {
    for (final code in [
      'too-many-requests',
      'network-request-failed',
      'user-disabled',
      'operation-not-allowed',
    ]) {
      final message = authErrorMessage(err(code), fallback: 'FALLBACK');
      expect(message, isNot('FALLBACK'), reason: code);
    }
  });

  test('raw Firebase text never reaches the message', () {
    const firebaseCopy =
        'We have blocked all requests from this device due to unusual activity.';
    final message =
        authErrorMessage(err('too-many-requests', firebaseCopy), fallback: 'x');

    expect(message, isNot(contains(firebaseCopy)));
    expect(message, isNot(contains('unusual activity')));
  });

  test('an unrecognised code uses the caller\'s own wording', () {
    expect(
      authErrorMessage(err('some-new-code'), fallback: 'Could not sign you in.'),
      'Could not sign you in.',
    );
  });

  test('a non-Firebase exception never leaks its toString()', () {
    final message = authErrorMessage(
      StateError('internal: connection pool exhausted at 0x7f'),
      fallback: 'Something went wrong.',
    );

    expect(message, 'Something went wrong.');
    expect(message, isNot(contains('0x7f')));
  });

  test('every message is plain sentence text, not a code dump', () {
    for (final code in [
      'user-not-found',
      'email-already-in-use',
      'weak-password',
      'user-disabled',
      'too-many-requests',
      'network-request-failed',
    ]) {
      final message = authErrorMessage(err(code), fallback: 'x');
      expect(message.trim(), isNotEmpty, reason: code);
      // The Firebase code itself must not surface - "Wi-Fi" is fine,
      // "network-request-failed" is not.
      expect(message, isNot(contains(code)), reason: '$code leaks its code');
      expect(message.endsWith('.'), isTrue, reason: code);
    }
  });
}
