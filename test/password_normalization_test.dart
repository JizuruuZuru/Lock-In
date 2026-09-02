import 'package:benchmark/utils/name_credential.dart';
import 'package:flutter_test/flutter_test.dart';

/// Login used to `.trim()` a typed password while register and the admin
/// account editor stored it untrimmed. A password created with a leading or
/// trailing space could therefore never be typed again - and there is no
/// password reset for a synthetic `@lockinplayers.app` address to recover
/// with, so the account was simply lost.
///
/// These lock the single rule in place: whatever creates a credential and
/// whatever verifies one must agree, exactly.
void main() {
  group('normalizePassword', () {
    test('strips the whitespace that used to lock students out', () {
      expect(normalizePassword(' hunter2'), 'hunter2');
      expect(normalizePassword('hunter2 '), 'hunter2');
      expect(normalizePassword('  hunter2  '), 'hunter2');
      expect(normalizePassword('\thunter2\n'), 'hunter2');
    });

    test('what register stores is what login sends', () {
      const typedAtRegistration = 'teacher123 ';
      const typedAtLogin = 'teacher123';

      expect(
        normalizePassword(typedAtRegistration),
        normalizePassword(typedAtLogin),
      );
    });

    test('leaves interior spaces alone - a passphrase stays a passphrase', () {
      expect(normalizePassword('two words'), 'two words');
      expect(normalizePassword('  two words  '), 'two words');
    });

    test('is idempotent, so normalising twice cannot drift', () {
      const raw = '  spaced out  ';
      expect(normalizePassword(normalizePassword(raw)), normalizePassword(raw));
    });

    test('an all-whitespace password collapses to empty, failing the 6-char '
        'rule rather than being stored as a typeable secret', () {
      expect(normalizePassword('      '), '');
      expect(normalizePassword('      ').length < 6, isTrue);
    });
  });
}
