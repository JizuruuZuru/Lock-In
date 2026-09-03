import 'package:benchmark/services/player_proctoring_preference.dart';
import 'package:benchmark/services/proctoring_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PlayerProctoringPreference build() =>
      PlayerProctoringPreference.forTesting(
        preferences: SharedPreferences.getInstance,
      );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a player who has never answered gets the camera on', () async {
    final preference = build();

    await preference.loadFor('child-a');

    expect(preference.optedIn.value, isTrue,
        reason: 'an anti-cheat feature must not default itself off');
  });

  test('an unreadable store still leaves the camera on', () async {
    final preference = PlayerProctoringPreference.forTesting(
      preferences: () async => throw StateError('no preference store'),
    );

    await preference.loadFor('child-a');

    expect(preference.optedIn.value, isTrue);
  });

  test('a saved answer survives a reload', () async {
    final preference = build();
    await preference.loadFor('child-a');

    await preference.setOptedIn(false);
    expect(preference.optedIn.value, isFalse);

    final reopened = build();
    await reopened.loadFor('child-a');
    expect(reopened.optedIn.value, isFalse);
  });

  test('two children on one tablet do not inherit each other\'s answer',
      () async {
    // The reason this is keyed by uid rather than being a plain per-device
    // setting: one child turning the camera off must not quietly turn it off
    // for whoever signs in next on a shared classroom device.
    final preference = build();
    await preference.loadFor('child-a');
    await preference.setOptedIn(false);

    await preference.loadFor('child-b');
    expect(preference.optedIn.value, isTrue);

    await preference.loadFor('child-a');
    expect(preference.optedIn.value, isFalse);
  });

  test('sign-out returns the default for the next account', () async {
    final preference = build();
    await preference.loadFor('child-a');
    await preference.setOptedIn(false);

    preference.reset();

    expect(preference.optedIn.value, isTrue);
    expect(preference.loadedUid, isNull);
  });

  test('a choice made with nobody signed in is not written anywhere', () async {
    final preference = build();

    // No `loadFor`, so there is no uid to key the write to. The switch still
    // moves - the UI must never appear stuck - it simply does not persist.
    await preference.setOptedIn(false);
    expect(preference.optedIn.value, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((key) => key.startsWith(
            PlayerProctoringPreference.keyPrefix,
          )),
      isEmpty,
    );
  });

  group('faceProctorEnabledFor', () {
    // Reads the two singletons the game screens read, so the gate is exercised
    // exactly as a round does. Neither needs a network: both are plain
    // ValueNotifiers until something calls `start()`.
    tearDown(() {
      ProctoringSettings.instance.config.value = ProctoringConfig.defaults;
      PlayerProctoringPreference.instance.reset();
    });

    Future<void> set({required bool teacher, required bool player}) async {
      ProctoringSettings.instance.config.value = ProctoringConfig(
        faceProctorExams: teacher,
        faceProctorLessons: teacher,
      );
      await PlayerProctoringPreference.instance.setOptedIn(player);
    }

    test('the camera opens only when both switches agree', () async {
      await set(teacher: true, player: true);
      expect(faceProctorEnabledFor(isExam: true), isTrue);
      expect(faceProctorEnabledFor(isExam: false), isTrue);
    });

    test('a player can decline within what the teacher allows', () async {
      await set(teacher: true, player: false);
      expect(faceProctorEnabledFor(isExam: true), isFalse);
      expect(faceProctorEnabledFor(isExam: false), isFalse);
    });

    test('a player cannot switch the camera back on', () async {
      // The one rule that must not bend: opting *in* is not permission to
      // override a teacher who turned proctoring off for the whole class.
      await set(teacher: false, player: true);
      expect(faceProctorEnabledFor(isExam: true), isFalse);
      expect(faceProctorEnabledFor(isExam: false), isFalse);
    });

    test('exams and lessons stay independent', () async {
      ProctoringSettings.instance.config.value = const ProctoringConfig(
        faceProctorExams: true,
        faceProctorLessons: false,
      );
      await PlayerProctoringPreference.instance.setOptedIn(true);

      expect(faceProctorEnabledFor(isExam: true), isTrue);
      expect(faceProctorEnabledFor(isExam: false), isFalse);
    });
  });
}
