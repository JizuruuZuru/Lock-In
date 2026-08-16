import 'dart:convert';
import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:benchmark/models/quiz_question_record.dart';
import 'package:benchmark/services/local_question_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The on-device mirror is what keeps teacher-made questions playable with no
/// network, so its round trip and its failure modes are tested directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QuizQuestionRecord buildRecord({
    String id = 'q1',
    String prompt = 'The bright sun warmed the park.',
    SubjectQuizType subject = SubjectQuizType.english,
    int minLevel = 1,
  }) {
    return QuizQuestionRecord(
      id: id,
      subject: subject,
      topic: 'Nouns',
      instruction: 'Choose the noun.',
      prompt: prompt,
      correctAnswer: 'sun',
      choices: const ['bright', 'warmed'],
      minLevel: minLevel,
      source: QuestionSource.openTrivia,
      createdAt: DateTime.utc(2026, 8, 13, 10, 30),
      updatedAt: DateTime.utc(2026, 8, 13, 11, 45),
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('QuizQuestionRecord cache serialization', () {
    test('round-trips every field including id and timestamps', () {
      final original = buildRecord(minLevel: 6);
      final restored =
          QuizQuestionRecord.fromCacheJson(original.toCacheJson());

      expect(restored.id, 'q1');
      expect(restored.subject, original.subject);
      expect(restored.topic, original.topic);
      expect(restored.instruction, original.instruction);
      expect(restored.prompt, original.prompt);
      expect(restored.correctAnswer, original.correctAnswer);
      expect(restored.choices, original.choices);
      expect(restored.minLevel, 6);
      expect(restored.source, QuestionSource.openTrivia);
      expect(restored.published, isTrue);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('survives a trip through real JSON encoding', () {
      final original = buildRecord();
      final decoded = jsonDecode(jsonEncode(original.toCacheJson()));
      final restored = QuizQuestionRecord.fromCacheJson(
        decoded as Map<String, dynamic>,
      );

      expect(restored.prompt, original.prompt);
      expect(restored.choices, original.choices);
      expect(restored.validate(), isEmpty);
    });
  });

  group('LocalQuestionCache', () {
    late LocalQuestionCache cache;

    setUp(() => cache = LocalQuestionCache());

    test('returns an empty list when nothing has been cached', () async {
      expect(await cache.load(), isEmpty);
      expect(await cache.lastSyncedAt(), isNull);
    });

    test('saves and reloads questions', () async {
      await cache.save([
        buildRecord(id: 'a', prompt: 'First cached question.'),
        buildRecord(
          id: 'b',
          prompt: 'Second cached question.',
          subject: SubjectQuizType.science,
        ),
      ]);

      final loaded = await cache.load();
      expect(loaded, hasLength(2));
      expect(loaded.map((r) => r.id), ['a', 'b']);
      expect(loaded.last.subject, SubjectQuizType.science);
    });

    test('records a sync time by default', () async {
      await cache.save([buildRecord()]);
      expect(await cache.lastSyncedAt(), isNotNull);
    });

    test('markSynced:false stores the questions but not a sync time', () async {
      // This is the offline path: data came from the local snapshot, so it
      // must not be presented to the user as "synced just now".
      await cache.save([buildRecord()], markSynced: false);

      expect(await cache.load(), hasLength(1));
      expect(await cache.lastSyncedAt(), isNull);
    });

    test('a later save replaces the previous copy so deletions propagate',
        () async {
      await cache.save([buildRecord(id: 'a'), buildRecord(id: 'b')]);
      await cache.save([buildRecord(id: 'a')]);

      final loaded = await cache.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'a');
    });

    test('saving an empty list clears the questions', () async {
      await cache.save([buildRecord()]);
      await cache.save(const []);
      expect(await cache.load(), isEmpty);
    });

    test('drops invalid records rather than serving an unanswerable question',
        () async {
      // One wrong choice is below the minimum, so this must never be played.
      const broken = QuizQuestionRecord(
        id: 'broken',
        subject: SubjectQuizType.english,
        topic: 'Nouns',
        instruction: 'Choose the noun.',
        prompt: 'A question with too few choices.',
        correctAnswer: 'sun',
        choices: ['bright'],
      );

      await cache.save([broken, buildRecord(id: 'good')]);

      final loaded = await cache.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'good');
    });

    test('a corrupt payload is ignored instead of crashing startup', () async {
      SharedPreferences.setMockInitialValues({
        LocalQuestionCache.questionsKey: 'not json at all',
      });

      expect(await LocalQuestionCache().load(), isEmpty);
    });

    test('a payload of the wrong shape is ignored', () async {
      SharedPreferences.setMockInitialValues({
        LocalQuestionCache.questionsKey: '{"unexpected":"object"}',
      });

      expect(await LocalQuestionCache().load(), isEmpty);
    });

    test('clear() removes both the questions and the sync time', () async {
      await cache.save([buildRecord()]);
      await cache.clear();

      expect(await cache.load(), isEmpty);
      expect(await cache.lastSyncedAt(), isNull);
    });
  });

  group('cached questions reach the game bank', () {
    tearDown(SubjectQuestionBank.clearCustomQuestions);

    test('a cached question is playable with no network involved', () async {
      final cache = LocalQuestionCache();
      await cache.save([
        buildRecord(id: 'offline-1', prompt: 'An offline-only question.'),
      ]);

      // Exactly what CustomQuestionSync does on launch, before Firestore is
      // ever contacted.
      final cached = await cache.load();
      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.english: [
          for (final record in cached)
            LeveledQuizQuestion(
              minLevel: record.minLevel,
              question: record.toQuizQuestion(),
            ),
        ],
      });

      expect(
        SubjectQuestionBank.customQuestionCountFor(SubjectQuizType.english),
        1,
      );

      final served = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.english,
        level: 1,
        random: Random(5),
        topics: {'Nouns'},
      );
      // The bundled bank also has "Nouns" questions, so assert the admin one is
      // in the pool rather than that it is the only possible draw.
      expect(
        SubjectQuestionBank.topicsFor(SubjectQuizType.english),
        contains('Nouns'),
      );
      expect(served.topic, 'Nouns');
    });
  });
}
