import 'dart:convert';

import 'package:benchmark/services/proctoring_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Face proctoring is now a teacher-owned switch rather than something the app
/// always does. These pin the two properties that matter most:
///
///  * it fails **on**, so a read failure can never quietly disable the
///    anti-cheat for a whole class;
///  * the last known answer survives a restart with no network, because the
///    setting has to be right on the very first frame of a game.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProctoringSettings settings() => ProctoringSettings.forTesting();

  group('ProctoringConfig', () {
    test('defaults to watching both exams and lessons', () {
      const config = ProctoringConfig.defaults;
      expect(config.faceProctorExams, isTrue);
      expect(config.faceProctorLessons, isTrue);
    });

    test('the two flags resolve independently', () {
      const examsOnly =
          ProctoringConfig(faceProctorExams: true, faceProctorLessons: false);

      expect(examsOnly.enabledFor(isExam: true), isTrue);
      expect(examsOnly.enabledFor(isExam: false), isFalse);

      const lessonsOnly =
          ProctoringConfig(faceProctorExams: false, faceProctorLessons: true);

      expect(lessonsOnly.enabledFor(isExam: true), isFalse);
      expect(lessonsOnly.enabledFor(isExam: false), isTrue);
    });

    test('a missing or malformed field falls back to on, never to off', () {
      // A half-written document must not be able to disable proctoring
      // everywhere - that is the failure mode worth guarding.
      expect(ProctoringConfig.fromMap(null), ProctoringConfig.defaults);
      expect(ProctoringConfig.fromMap(const {}), ProctoringConfig.defaults);
      expect(
        ProctoringConfig.fromMap(const {'faceProctorExams': 'yes'}),
        ProctoringConfig.defaults,
      );
      expect(
        ProctoringConfig.fromMap(const {'faceProctorLessons': null}),
        ProctoringConfig.defaults,
      );
    });

    test('an explicit false is honoured', () {
      final config = ProctoringConfig.fromMap(const {
        'faceProctorExams': false,
        'faceProctorLessons': false,
      });

      expect(config.faceProctorExams, isFalse);
      expect(config.faceProctorLessons, isFalse);
    });

    test('round-trips through JSON', () {
      const original =
          ProctoringConfig(faceProctorExams: false, faceProctorLessons: true);

      expect(
        ProctoringConfig.fromMap(jsonDecode(jsonEncode(original.toJson()))),
        original,
      );
    });
  });

  group('offline copy', () {
    test('starts at the defaults when nothing has ever been cached', () async {
      final service = settings();
      await service.loadFromCache();

      expect(service.config.value, ProctoringConfig.defaults);
      expect(service.source.value, ProctoringSource.idle,
          reason: 'nothing was loaded, so nothing is the source');
    });

    test('restores the last known settings with no network', () async {
      final writer = settings();
      await writer.writeCache(
        const ProctoringConfig(
          faceProctorExams: true,
          faceProctorLessons: false,
        ),
      );

      // A fresh launch: same on-device store, no Firestore.
      final reader = settings();
      await reader.loadFromCache();

      expect(reader.config.value.faceProctorExams, isTrue);
      expect(reader.config.value.faceProctorLessons, isFalse);
      expect(reader.source.value, ProctoringSource.localCache);
      expect(reader.lastSyncedAt.value, isNotNull);
    });

    test('a corrupt cache is ignored rather than crashing the launch',
        () async {
      SharedPreferences.setMockInitialValues({
        ProctoringSettings.cacheKey: 'not json at all',
      });

      final service = settings();
      await service.loadFromCache();

      expect(service.config.value, ProctoringConfig.defaults);
    });

    test('a cache holding the wrong shape falls back to the defaults',
        () async {
      SharedPreferences.setMockInitialValues({
        ProctoringSettings.cacheKey: jsonEncode([1, 2, 3]),
      });

      final service = settings();
      await service.loadFromCache();

      expect(service.config.value, ProctoringConfig.defaults);
    });
  });

  group('enabledFor', () {
    test('reads through to the current config', () async {
      final service = settings();
      await service.writeCache(
        const ProctoringConfig(
          faceProctorExams: false,
          faceProctorLessons: true,
        ),
      );
      await service.loadFromCache();

      expect(service.enabledFor(isExam: true), isFalse);
      expect(service.enabledFor(isExam: false), isTrue);
    });
  });
}
