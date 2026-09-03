import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/player_proctoring_preference.dart';
import '../../services/game_result_recorder.dart';
import '../../data/subject_question_bank.dart';
import '../../services/connectivity_service.dart';
import '../../services/game_logger.dart';
import '../../services/exam_firestore_service.dart';
import '../../services/face_proctor_contract.dart';
import '../../services/face_proctor_service.dart';
import '../../services/leave_attempt_logger.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/game_difficulty_mode.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/app_brightness_overlay.dart';
import '../../widgets/correct_splash.dart';
import '../../widgets/difficulty_mode_selector.dart';
import '../../widgets/game_over_popup.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/hearts_display.dart';
import '../../widgets/incorrect_splash.dart';
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/game_security_overlay.dart';
import '../../widgets/level_up_popup.dart';

String _examDifficultyName(ExamDifficulty difficulty) {
  switch (difficulty) {
    case ExamDifficulty.easy:
      return 'Easy';
    case ExamDifficulty.medium:
      return 'Medium';
    case ExamDifficulty.hard:
      return 'Hard';
  }
}

enum ExamDifficulty { easy, medium, hard }

enum ExamSubjectSelection { english, math, science }

const _allExamSubjects = <ExamSubjectSelection>{
  ExamSubjectSelection.english,
  ExamSubjectSelection.math,
  ExamSubjectSelection.science,
};

/// Short, player-facing name for a single exam subject.
String examSubjectSelectionLabel(ExamSubjectSelection selection) {
  switch (selection) {
    case ExamSubjectSelection.english:
      return 'English';
    case ExamSubjectSelection.math:
      return 'Math';
    case ExamSubjectSelection.science:
      return 'Science';
  }
}

/// Heading-friendly name for a freely-chosen combination of subjects, e.g.
/// "English", "English + Science", or "All Subjects" when everything is
/// selected.
String examSubjectSetTitle(Set<ExamSubjectSelection> subjects) {
  if (subjects.length >= _allExamSubjects.length) return 'All Subjects';
  return ExamSubjectSelection.values
      .where(subjects.contains)
      .map(examSubjectSelectionLabel)
      .join(' + ');
}

class ExamGame extends StatefulWidget {
  final ExamDifficulty difficulty;
  final Set<ExamSubjectSelection> subjectSelection;

  const ExamGame({
    super.key,
    required this.difficulty,
    this.subjectSelection = _allExamSubjects,
  });

  @override
  State<ExamGame> createState() => _ExamGameState();
}

class _ExamQuestion {
  final String topic;
  final String instruction;
  final String prompt;
  final List<String> acceptedAnswers;
  final List<String>? choices;
  final int? hour;
  final int? minute;

  const _ExamQuestion({
    required this.topic,
    required this.instruction,
    required this.prompt,
    required this.acceptedAnswers,
    this.choices,
    this.hour,
    this.minute,
  });

  _ExamQuestion shuffledChoices(Random random) {
    final answerChoices = choices;
    if (answerChoices == null || answerChoices.isEmpty) return this;
    final shuffled = [...answerChoices]..shuffle(random);
    return _ExamQuestion(
      topic: topic,
      instruction: instruction,
      prompt: prompt,
      acceptedAnswers: acceptedAnswers,
      choices: shuffled,
      hour: hour,
      minute: minute,
    );
  }
}

/// A question generator paired with the subject it asks about, so the subject
/// filter never has to generate a question just to classify it.
typedef _ExamQuestionBuilder = ({
  ExamSubjectSelection subject,
  _ExamQuestion Function() build,
});

class _ExamGameState extends State<ExamGame> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1450);

  final Random _random = Random();

  /// Keys of questions already served this run, so the bank does not repeat
  /// one before the pool is exhausted.
  final Set<String> _askedQuestionKeys = <String>{};
  final FaceProctorService _faceProctor = createFaceProctorService();
  final ExamFirestoreService _firestoreService = ExamFirestoreService();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;
  final GameSaveGate _saveGate = GameSaveGate();

  /// Whether the camera is actually watching this run.
  ///
  /// Starts false and is set by [GameSecurityOverlay.onProctorWatchingChanged]
  /// once the start attempt resolves, so the saved score - and the leaderboard
  /// badge it feeds - tells the truth in every case: the teacher switched
  /// proctoring off, the player declined it in their own settings, or the
  /// camera could not be opened.
  bool _runProctored = false;

  /// The pause between answering and the next question.
  ///
  /// Was an un-cancellable `Future.delayed`. Its callback calls
  /// `generateQuestion()`, which sets `isGameOver = false` and mints a fresh
  /// `timerKey` - so a face violation or an app-background landing inside that
  /// window put the "Leave / Stay" overlay on screen with a live timer
  /// counting down underneath it, and the player lost a heart to a question
  /// they could not see. Cancelled when the overlay locks, and on dispose.
  Timer? _feedbackTimer;
  bool _isOffline = false;

  int score = 0;
  int _levelPoints = 0;
  int level = 1;
  int hearts = 3;
  int timeLimit = 18;
  int _attemptsLogged = 0;
  late Set<ExamSubjectSelection> _selectedSubjects;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  String input = '';
  _ExamQuestion question = const _ExamQuestion(
    topic: 'Addition',
    instruction: 'Solve the addition problem.',
    prompt: '8 + 7 = ___',
    acceptedAnswers: ['15'],
  );
  Key timerKey = UniqueKey();

  String get _difficultyName => _examDifficultyName(widget.difficulty);
  String get _subjectLabel => examSubjectSetTitle(_selectedSubjects);
  String get _gameName => '$_subjectLabel $_difficultyName Exam';

  @override
  void initState() {
    super.initState();
    _selectedSubjects = widget.subjectSelection.isEmpty
        ? Set.of(_allExamSubjects)
        : Set.of(widget.subjectSelection);
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
    _refreshOfflineState();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    GameLogger.endSession(_gameName);
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  Future<void> _refreshOfflineState() async {
    final offline = await ConnectivityService.isOffline();
    if (!mounted) return;
    setState(() => _isOffline = offline);
  }

  void startGame() {
    GameLogger.startNewSession(_gameName);
    _refreshOfflineState();
    setState(() {
      hasStarted = true;
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      score = 0;
      _levelPoints = 0;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      input = '';
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  int _rand(int min, int max) => min + _random.nextInt(max - min + 1);

  /// The builders for [widget.difficulty], each tagged with the subject it
  /// asks about.
  ///
  /// The tag is declared here rather than derived from the question's topic,
  /// because deriving it meant *building* a question purely to read its topic
  /// and then throwing it away - once per candidate, on every question the
  /// player was served, and consuming random state as a side effect.
  List<_ExamQuestionBuilder> _buildQuestionPool() {
    const math = ExamSubjectSelection.math;
    const english = ExamSubjectSelection.english;
    const science = ExamSubjectSelection.science;

    final baseBuilders = switch (widget.difficulty) {
      ExamDifficulty.easy => <_ExamQuestionBuilder>[
          (subject: math, build: _additionQuestion),
          (subject: math, build: _subtractionQuestion),
          (subject: math, build: _romanQuestion),
          (subject: math, build: _placeValueQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: science, build: _scienceBankQuestion),
          (subject: science, build: _scienceBankQuestion),
        ],
      ExamDifficulty.medium => <_ExamQuestionBuilder>[
          (subject: math, build: _multiplicationQuestion),
          (subject: math, build: _divisionQuestion),
          (subject: math, build: _roundingQuestion),
          (subject: math, build: _analogClockQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: science, build: _scienceBankQuestion),
          (subject: science, build: _scienceBankQuestion),
        ],
      ExamDifficulty.hard => <_ExamQuestionBuilder>[
          (subject: math, build: _orderOperationsQuestion),
          (subject: math, build: _fractionQuestion),
          (subject: math, build: _measurementQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: english, build: _englishBankQuestion),
          (subject: science, build: _scienceBankQuestion),
          (subject: science, build: _scienceBankQuestion),
        ],
    };

    if (_selectedSubjects.length >= _allExamSubjects.length) {
      return baseBuilders;
    }

    final filtered = baseBuilders
        .where((item) => _selectedSubjects.contains(item.subject))
        .toList();

    // Guard against an empty pool (shouldn't happen — the chips always
    // keep at least one subject selected) rather than crashing the exam.
    return filtered.isEmpty ? baseBuilders : filtered;
  }

  /// Draws a real question from [SubjectQuestionBank] instead of returning a
  /// fixed one.
  ///
  /// Maths in this exam is procedural and effectively unbounded, but every
  /// English and Science question used to be a `const _ExamQuestion` with fixed
  /// text - two per subject per difficulty, and Hard reused Easy's two
  /// verbatim. So "English Hard Exam" served the same two easy questions
  /// forever, while 5,793 bundled questions sat unused and the start panel
  /// promised "Questions are randomized every round."
  ///
  /// [_askedQuestionKeys] stops a question repeating inside one run; when the
  /// pool is exhausted the bank widens on its own rather than returning
  /// nothing.
  _ExamQuestion _bankQuestion(SubjectQuizType subject) {
    final drawn = SubjectQuestionBank.randomQuestion(
      subject: subject,
      level: _bankLevel,
      random: _random,
      excludeKeys: _askedQuestionKeys,
    ).shuffled(_random);

    _askedQuestionKeys.add(SubjectQuestionBank.questionKey(drawn));

    final subjectLabel = subject == SubjectQuizType.english
        ? 'English'
        : 'Science';

    return _ExamQuestion(
      topic: '$subjectLabel: ${drawn.topic}',
      instruction: drawn.instruction,
      prompt: drawn.prompt,
      acceptedAnswers: [drawn.correctAnswer],
      choices: drawn.choices,
    );
  }

  /// The bank gates questions by `minLevel`, so the exam's own difficulty maps
  /// onto it: an Easy exam draws from level-1 material, Hard from the top.
  int get _bankLevel => switch (widget.difficulty) {
        ExamDifficulty.easy => 1,
        ExamDifficulty.medium => 2,
        ExamDifficulty.hard => 4,
      };

  _ExamQuestion _englishBankQuestion() =>
      _bankQuestion(SubjectQuizType.english);

  _ExamQuestion _scienceBankQuestion() =>
      _bankQuestion(SubjectQuizType.science);

  bool _isEnglishTopic(String topic) {
    final normalizedTopic = topic.toLowerCase();
    return normalizedTopic.contains('english') ||
        normalizedTopic.contains('grammar') ||
        normalizedTopic.contains('reading') ||
        normalizedTopic.contains('vocabulary') ||
        normalizedTopic.contains('phonics');
  }

  bool _isScienceTopic(String topic) {
    final normalizedTopic = topic.toLowerCase();
    return normalizedTopic.contains('science') ||
        normalizedTopic.contains('living') ||
        normalizedTopic.contains('weather') ||
        normalizedTopic.contains('body') ||
        normalizedTopic.contains('energy') ||
        normalizedTopic.contains('matter') ||
        normalizedTopic.contains('space');
  }

  void generateQuestion() {
    final builders = _buildQuestionPool();
    if (builders.isEmpty) {
      return;
    }

    final next = builders[_random.nextInt(builders.length)]
        .build()
        .shuffledChoices(_random);
    setState(() {
      question = next;
      input = '';
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });
  }

  int _timeLimitForLevel() {
    if (widget.difficulty == ExamDifficulty.easy) return level <= 3 ? 18 : 16;
    if (widget.difficulty == ExamDifficulty.medium) return level <= 3 ? 20 : 18;
    return level <= 3 ? 24 : 21;
  }

  _ExamQuestion _additionQuestion() {
    final a = _rand(5, 120 + level * 8);
    final b = _rand(4, 120 + level * 8);
    return _ExamQuestion(
      topic: 'Addition',
      instruction: 'Add the numbers.',
      prompt: '$a + $b = ___',
      acceptedAnswers: ['${a + b}'],
    );
  }

  _ExamQuestion _subtractionQuestion() {
    final b = _rand(5, 120 + level * 8);
    final answer = _rand(2, 120 + level * 8);
    final a = b + answer;
    return _ExamQuestion(
      topic: 'Subtraction',
      instruction: 'Subtract the numbers.',
      prompt: '$a - $b = ___',
      acceptedAnswers: ['$answer'],
    );
  }

  String _toRoman(int number) {
    final values = <int, String>{
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    var remaining = number;
    final buffer = StringBuffer();
    for (final entry in values.entries) {
      while (remaining >= entry.key) {
        buffer.write(entry.value);
        remaining -= entry.key;
      }
    }
    return buffer.toString();
  }

  _ExamQuestion _romanQuestion() {
    final value = _rand(4, 80 + level * 6);
    final roman = _toRoman(value);
    return _ExamQuestion(
      topic: 'Roman Numerals',
      instruction: 'Write the number represented by the Roman numeral.',
      prompt: '$roman = ___',
      acceptedAnswers: ['$value'],
    );
  }

  _ExamQuestion _placeValueQuestion() {
    final thousands = _rand(1, 8) * 1000;
    final hundreds = _rand(1, 9) * 100;
    final tens = _rand(1, 9) * 10;
    final ones = _rand(1, 9);
    final value = thousands + hundreds + tens + ones;
    final type = _random.nextInt(3);
    if (type == 0) {
      return _ExamQuestion(
        topic: 'Place Value',
        instruction: 'Build the number from its parts.',
        prompt: '$thousands + $hundreds + $tens + $ones = ___',
        acceptedAnswers: ['$value'],
      );
    }
    if (type == 1) {
      return _ExamQuestion(
        topic: 'Place Value',
        instruction: 'Find the missing hundreds value.',
        prompt: '$thousands + ___ + $tens + $ones = $value',
        acceptedAnswers: ['$hundreds'],
      );
    }
    return _ExamQuestion(
      topic: 'Place Value',
      instruction: 'Find the missing thousands value.',
      prompt: '___ + $hundreds + $tens + $ones = $value',
      acceptedAnswers: ['$thousands'],
    );
  }

  _ExamQuestion _multiplicationQuestion() {
    final a = _rand(2, 12 + min(level, 6));
    final b = _rand(2, 12 + min(level, 6));
    return _ExamQuestion(
      topic: 'Multiplication',
      instruction: 'Multiply the numbers.',
      prompt: '$a × $b = ___',
      acceptedAnswers: ['${a * b}'],
    );
  }

  _ExamQuestion _divisionQuestion() {
    final divisor = _rand(2, 12 + min(level, 5));
    final answer = _rand(2, 14 + min(level, 6));
    final dividend = divisor * answer;
    return _ExamQuestion(
      topic: 'Division',
      instruction: 'Divide. The answer is a whole number.',
      prompt: '$dividend ÷ $divisor = ___',
      acceptedAnswers: ['$answer'],
    );
  }

  int _roundTo(int value, int place) {
    return ((value / place).round() * place).toInt();
  }

  _ExamQuestion _roundingQuestion() {
    final places = widget.difficulty == ExamDifficulty.medium
        ? <int>[10, 100, 1000]
        : <int>[10, 100];
    final place = places[_random.nextInt(places.length)];
    final max = place == 1000 ? 10000 : 9000;
    final value = _rand(45, max);
    final answer = _roundTo(value, place);
    final label = place == 10 ? 'nearest ten' : place == 100 ? 'nearest hundred' : 'nearest thousand';
    return _ExamQuestion(
      topic: 'Rounding Numbers',
      instruction: 'Round the number to the $label.',
      prompt: '$value rounds to ___',
      acceptedAnswers: ['$answer'],
    );
  }

  _ExamQuestion _analogClockQuestion() {
    final hour = _rand(1, 12);
    final minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    final minute = minuteOptions[_random.nextInt(minuteOptions.length)];
    final answer = '$hour:${minute.toString().padLeft(2, '0')}';
    return _ExamQuestion(
      topic: 'Analog Clock',
      instruction: 'What time is shown on the clock?',
      prompt: 'Enter the time as h:mm.',
      acceptedAnswers: [answer, answer.replaceAll(':', '')],
      hour: hour,
      minute: minute,
    );
  }

  _ExamQuestion _orderOperationsQuestion() {
    final type = _random.nextInt(4);
    if (type == 0) {
      final b = _rand(3, 16);
      final c = _rand(3, 16);
      final a = b + c + _rand(5, 35);
      return _ExamQuestion(
        topic: 'Order of Operations',
        instruction: 'Solve using parentheses first.',
        prompt: '$a - ($b + $c) = ___',
        acceptedAnswers: ['${a - (b + c)}'],
      );
    }
    if (type == 1) {
      final a = _rand(2, 24);
      final b = _rand(2, 9);
      final c = _rand(2, 14);
      final d = _rand(2, 14);
      return _ExamQuestion(
        topic: 'Order of Operations',
        instruction: 'Multiply after solving the parentheses.',
        prompt: '$a + $b × ($c + $d) = ___',
        acceptedAnswers: ['${a + b * (c + d)}'],
      );
    }
    if (type == 2) {
      final a = _rand(3, 24);
      final b = _rand(2, 10);
      final c = _rand(2, 10);
      final d = _rand(2, 24);
      return _ExamQuestion(
        topic: 'Order of Operations',
        instruction: 'Use multiplication before addition and subtraction.',
        prompt: '$a + $b × $c - $d = ___',
        acceptedAnswers: ['${a + b * c - d}'],
      );
    }
    final a = _rand(10, 35);
    final b = _rand(5, 20);
    final c = _rand(3, 15);
    final d = _rand(15, 40);
    final e = _rand(3, 14);
    return _ExamQuestion(
      topic: 'Order of Operations',
      instruction: 'Solve both parentheses before the final subtraction.',
      prompt: '($a + $b) + $c - ($d + $e) = ___',
      acceptedAnswers: ['${(a + b) + c - (d + e)}'],
    );
  }

  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }

  String _simplify(int numerator, int denominator) {
    final g = _gcd(numerator, denominator);
    numerator ~/= g;
    denominator ~/= g;
    if (denominator == 1) return '$numerator';
    return '$numerator/$denominator';
  }

  _ExamQuestion _fractionQuestion() {
    final type = _random.nextInt(5);
    if (type == 0) {
      final d = _rand(3, 12);
      final a = _rand(1, d - 1);
      final b = _rand(1, d - a);
      return _ExamQuestion(
        topic: 'Fractions',
        instruction: 'Add like fractions. Simplify if needed.',
        prompt: '$a/$d + $b/$d = ___',
        acceptedAnswers: [_simplify(a + b, d), '${a + b}/$d'],
      );
    }
    if (type == 1) {
      final d = _rand(3, 12);
      final a = _rand(2, d);
      final b = _rand(1, a - 1);
      return _ExamQuestion(
        topic: 'Fractions',
        instruction: 'Subtract like fractions. Simplify if needed.',
        prompt: '$a/$d - $b/$d = ___',
        acceptedAnswers: [_simplify(a - b, d), '${a - b}/$d'],
      );
    }
    if (type == 2) {
      final d = _rand(4, 12);
      final g = _rand(2, 4);
      final numerator = _rand(1, d - 1) * g;
      final denominator = d * g;
      return _ExamQuestion(
        topic: 'Fractions',
        instruction: 'Simplify the fraction.',
        prompt: '$numerator/$denominator = ___',
        acceptedAnswers: [_simplify(numerator, denominator)],
      );
    }
    if (type == 3) {
      final n = _rand(1, 9);
      final d = _rand(2, 10);
      final multiplier = _rand(2, 8);
      return _ExamQuestion(
        topic: 'Fractions',
        instruction: 'Find the missing numerator.',
        prompt: '$n/$d = ___/${d * multiplier}',
        acceptedAnswers: ['${n * multiplier}'],
      );
    }
    final whole = _rand(1, 6);
    final d = _rand(2, 9);
    final n = _rand(1, d - 1);
    return _ExamQuestion(
      topic: 'Fractions',
      instruction: 'Convert the mixed number to an improper fraction.',
      prompt: '$whole $n/$d = ___',
      acceptedAnswers: ['${whole * d + n}/$d'],
    );
  }

  String _decimalString(double value) {
    final s = value.toStringAsFixed(2);
    return s.endsWith('00') ? value.toStringAsFixed(0) : s.replaceFirst(_examTrailingZero, '');
  }

  _ExamQuestion _measurementQuestion() {
    final type = _random.nextInt(7);
    if (type == 0) {
      final yards = _rand(2, 20);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert feet to yards.',
        prompt: '${yards * 3} ft = ___ yd',
        acceptedAnswers: ['$yards'],
      );
    }
    if (type == 1) {
      final pounds = _rand(1, 12);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert pounds to ounces.',
        prompt: '$pounds lb = ___ oz',
        acceptedAnswers: ['${pounds * 16}'],
      );
    }
    if (type == 2) {
      final kg = _rand(1, 15);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert kilograms to grams.',
        prompt: '$kg kg = ___ g',
        acceptedAnswers: ['${kg * 1000}'],
      );
    }
    if (type == 3) {
      final liters = _rand(1, 12);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert liters to milliliters.',
        prompt: '$liters L = ___ mL',
        acceptedAnswers: ['${liters * 1000}'],
      );
    }
    if (type == 4) {
      final mm = _rand(10, 200);
      final answer = _decimalString(mm / 10);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert millimeters to centimeters.',
        prompt: '$mm mm = ___ cm',
        acceptedAnswers: [answer],
      );
    }
    if (type == 5) {
      final gallons = _rand(1, 10);
      return _ExamQuestion(
        topic: 'Measurements',
        instruction: 'Convert gallons to quarts.',
        prompt: '$gallons gal = ___ qt',
        acceptedAnswers: ['${gallons * 4}'],
      );
    }
    final meters = _rand(1, 50);
    return _ExamQuestion(
      topic: 'Measurements',
      instruction: 'Convert meters to centimeters.',
      prompt: '$meters m = ___ cm',
      acceptedAnswers: ['${meters * 100}'],
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(',', '')
        .replaceAll('×', 'x')
        .replaceAll('÷', '/')
        .replaceAll(_examWhitespaceRun, ' ')
        .trim();
  }

  bool _isCorrectAnswer(String value) {
    final normalized = _normalize(value);
    return question.acceptedAnswers.any((answer) => _normalize(answer) == normalized);
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    if (value == 'space') {
      if (input.isNotEmpty && !input.endsWith(' ')) {
        setState(() => input += ' ');
      }
      return;
    }
    if (value == 'backspace') {
      if (input.isNotEmpty) {
        setState(() => input = input.substring(0, input.length - 1));
      }
      return;
    }
    if (input.length >= 18) return;
    setState(() => input += value);
  }

  void clearInput() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    setState(() => input = '');
  }

  void submitInput() {
    if (isGameOver || input.trim().isEmpty) return;
    SoundService().playButtonSoundNow();
    _submitAnswer(input.trim());
  }

  void submitChoice(String choice) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    setState(() => input = choice);
    _submitAnswer(choice);
  }

  void _submitAnswer(String submittedAnswer) {
    final isCorrect = _isCorrectAnswer(submittedAnswer);

    unawaited(_firestoreService.logAttempt(
      gameName: _gameName,
      difficulty: _difficultyName,
      selectedSubjects: _selectedSubjectsForExam(),
      subject: _subjectForTopic(question.topic),
      topic: question.topic,
      prompt: question.prompt,
      correctAnswer: question.acceptedAnswers.first,
      submittedAnswer: submittedAnswer,
      isCorrect: isCorrect,
      score: score,
      level: level,
      proctored: _runProctored,
    ));

    if (isCorrect) {
      SoundService().playCorrectSound();
      final nextLevelPoints = _levelPoints + 10 + ((level - 1) * 2);
      final nextLevel = (nextLevelPoints ~/ 50) + 1;
      final didLevelUp = nextLevel > level;

      setState(() {
        score += 1;
        _levelPoints = nextLevelPoints;
        if (didLevelUp) level = nextLevel;
        showCorrectSplash = true;
        isGameOver = true;
      });

      _feedbackTimer = Timer(_correctFeedbackDuration, () {
        if (!mounted) return;
        setState(() => showCorrectSplash = false);

        if (didLevelUp) {
          showLevelUpPage();
        } else {
          setState(() => isGameOver = false);
          generateQuestion();
        }
      });
      return;
    }

    _handleIncorrect(submittedAnswer);
  }

  String _subjectForTopic(String topic) {
    if (_isEnglishTopic(topic)) return 'English';
    if (_isScienceTopic(topic)) return 'Science';
    return 'Math';
  }

  void _handleTimeout() {
    if (isGameOver) return;
    _handleIncorrect('Time out');
  }

  List<String> _selectedSubjectsForExam() {
    return ExamSubjectSelection.values
        .where(_selectedSubjects.contains)
        .map(examSubjectSelectionLabel)
        .toList();
  }

  void _handleIncorrect(String incorrectAnswer) {
    SoundService().playIncorrectSplashSound();
    setState(() {
      hearts--;
      isGameOver = true;
      showIncorrectSplash = true;
    });

    unawaited(saveScore().catchError((Object error) {
      debugPrint('Error saving Exam score: $error');
    }));

    _feedbackTimer = Timer(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() => showIncorrectSplash = false);
      showGameOverScreen(incorrectAnswer);
    });
  }

  Future<void> _saveSessionSnapshot() async {
    await _firestoreService.saveSession(
      gameName: _gameName,
      difficulty: _difficultyName,
      selectedSubjects: _selectedSubjectsForExam(),
      score: score,
      level: level,
      hearts: hearts,
      attempts: _attemptsLogged,
      proctored: _runProctored,
    );
  }

  void showLevelUpPage() {
    isGameOver = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpPopup(
        newLevel: level,
        message: 'Great job! The next exam level uses harder randomized questions.',
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            isGameOver = false;
            timerKey = UniqueKey();
          });
          generateQuestion();
        },
      ),
    );
  }

  void showGameOverScreen(String incorrectAnswer) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverPopup(
        incorrectAnswer: incorrectAnswer,
        correctAnswer: question.acceptedAnswers.first,
        heartsRemaining: hearts,
        score: hearts <= 0 ? score : null,
        level: hearts <= 0 ? level : null,
        onRetry: () {
          Navigator.pop(context);
          if (hearts <= 0) {
            startGame();
          } else {
            setState(() {
              input = '';
              timerKey = UniqueKey();
              isGameOver = false;
            });
            generateQuestion();
          }
        },
        onBack: () {
          Navigator.pop(context);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  bool _shouldConfirmExit() {
    return hasStarted &&
        !_showExitConfirmation &&
        !showCorrectSplash &&
        !showIncorrectSplash &&
        !isGameOver;
  }

  void _showExitConfirmationOverlay() {
    if (!_shouldConfirmExit()) return;
    SoundService().playButtonSoundNow();
    setState(() {
      isGameOver = true;
      _showExitConfirmation = true;
    });
  }

  void _cancelExitConfirmation() {
    SoundService().playButtonSoundNow();
    if (!mounted) return;
    setState(() {
      _showExitConfirmation = false;
      isGameOver = false;
      timerKey = UniqueKey();
    });
  }

  Future<void> _confirmExitFromBack() async {
    SoundService().playButtonSoundNow();

    // Both writes are issued here, so each reaches Firestore's local
    // cache straight away - but neither acknowledgement is allowed to
    // hold up leaving. Awaiting them is what made this button stop
    // responding entirely on a device with no connection.
    await saveBeforeLeaving(() async {
      await Future.wait<void>([
        LeaveAttemptLogger.logAttempt(
          gameName: _gameName,
          reason: 'player_pressed_back_while_playing',
          source: 'back_button',
          details: {
            'score': score,
            'level': level,
          },
        ).catchError((Object error) {
          debugPrint('Leave attempt log failed: $error');
        }),
        saveScore(),
      ]);
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> saveScore() async {
    await _saveGate.run(() async {
      _attemptsLogged += 1;
      await saveGameResult(
        gameName: _gameName,
        score: score,
        level: level,
        difficulty: gameDifficultyModeLabel(_selectedMode),
        proctored: _runProctored,
        storageKey: '${_difficultyName.toLowerCase()}_exam',
      );
      await _saveSessionSnapshot();
    });
  }

  Future<void> _onBackPressed() async {
    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    SoundService().playButtonSoundNow();
    if (hasStarted && score > 0) {
      // Bounded: offline this never returned, so the back arrow did nothing.
      await saveBeforeLeaving(saveScore);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // The screen drives every exit through _onBackPressed: it confirms, logs the
    // leave attempt, and saves the score. The Android hardware/gesture back
    // popped the route directly and skipped all three - no confirmation, no
    // score, and no proctoring record. `canPop: false` routes that gesture
    // into the same handler the on-screen arrow uses.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: _buildGameScreen(context),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _onBackPressed,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            title: Text('$_subjectLabel $_difficultyName Exam'),
          ),
          body: Stack(
            children: [
              _buildBackground(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: hasStarted ? _buildGameUI() : _buildStartPanel(),
                  ),
                ),
              ),
              GameSecurityOverlay(
                      enableFaceProctor: faceProctorEnabledFor(isExam: true),
                      onProctorWatchingChanged: (watching) => _runProctored = watching,
                      faceProctor: _faceProctor,
                      gameName: _gameName,
                      isActive: hasStarted && !isGameOver && !showCorrectSplash && !showIncorrectSplash && !_showExitConfirmation,
                      onLockChanged: (locked) {
                        if (!mounted) return;
                        setState(() {
                          isGameOver = locked;
                          if (locked) {
                            // Drop any pending "next question" callback, or it
                            // will restart the round behind this overlay.
                            _feedbackTimer?.cancel();
                            showCorrectSplash = false;
                            showIncorrectSplash = false;
                            _showExitConfirmation = false;
                          } else {
                            timerKey = UniqueKey();
                          }
                        });
                      },
                      onLeave: () async {
                        if (score > 0) {
                          await saveBeforeLeaving(saveScore);
                        }
                      },
                      onStay: () {
                        startGame();
                      },
                      onAttemptRecorded: () async {
                        await saveScore();
                      },
                    ),
                    if (_showExitConfirmation)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Leave game?',
                    message: 'Your current progress in this exam will be saved before leaving.',
                    onOk: _confirmExitFromBack,
                    onBack: _cancelExitConfirmation,
                    okText: 'Leave',
                    backText: 'Stay',
                  ),
                ),
              if (showCorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CorrectSplash(duration: _correctFeedbackDuration),
                  ),
                ),
              if (showIncorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: IncorrectSplash(duration: _incorrectFeedbackDuration),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    return buildGameTheme(context, ink: _inkColor, accent: _accentColor);
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.diamond,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-38, -24),
          drift: Offset(16, 12),
          size: 150,
          color: Color(0x334CAF50),
          borderColor: Color(0x4D2F5233),
          initialRotation: -0.2,
          cornerRadius: 20,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(22, 30),
          drift: Offset(10, 15),
          size: 100,
          color: Color(0x26FF9800),
          borderColor: Color(0x442F5233),
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return gameCard(
      child: child,
      panel: _panelColor,
      ink: _inkColor,
      padding: padding,
    );
  }

  String _topicSummary() {
    final subjectLabel = _subjectLabel;

    final difficultyTopics = switch (widget.difficulty) {
      ExamDifficulty.easy => 'Addition • Subtraction • Roman Numerals • Place Value • Grammar • Reading',
      ExamDifficulty.medium => 'Multiplication • Division • Rounding Numbers • Analog Clock • Vocabulary • Phonics',
      ExamDifficulty.hard => 'Order of Operations • Fractions • Measurements • Science Facts • Space & Matter',
    };

    return '$subjectLabel • $difficultyTopics';
  }

  Widget _buildStartPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxPanelWidth = responsivePanelMaxWidth(width);
        final gap14 = responsiveCompactGap(width, 14);
        final gap12 = responsiveCompactGap(width, 12);
        final gap8 = responsiveCompactGap(width, 8);
        final gap6 = responsiveCompactGap(width, 6);
        final gap4 = responsiveCompactGap(width, 4);
        final titleFontSize = isDesktopLayout(width) ? 24.0 : 30.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxPanelWidth),
            child: _card(
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_subjectLabel $_difficultyName Exam',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: gap8),
                  const Text(
                    'Questions are randomized every round.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: gap12),
                  const Text(
                    'Subjects (tap any combination)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: gap6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _subjectChip('English', ExamSubjectSelection.english),
                      _subjectChip('Math', ExamSubjectSelection.math),
                      _subjectChip('Science', ExamSubjectSelection.science),
                    ],
                  ),
                  SizedBox(height: gap14),
                  const Text(
                    'Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: gap6),
                  DifficultyModeSelector(
                    selected: _selectedMode,
                    accentColor: _accentColor,
                    onChanged: (mode) => setState(() => _selectedMode = mode),
                  ),
                  SizedBox(height: gap4),
                  Text(
                    gameDifficultyModeDescription(_selectedMode),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: gap14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _inkColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _topicSummary(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_isOffline) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: Color(0xFFE65100),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No connection detected. This exam can still play locally, but its history will stay on the device until you reconnect.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: startGame,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Start $_subjectLabel $_difficultyName Exam'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(responsiveButtonHeight(MediaQuery.sizeOf(context).width)),
                        padding: EdgeInsets.symmetric(vertical: responsiveButtonHeight(MediaQuery.sizeOf(context).width) / 2.4),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _subjectChip(String label, ExamSubjectSelection subject) {
    final isSelected = _selectedSubjects.contains(subject);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: _accentColor.withValues(alpha: 0.18),
      onSelected: (selected) {
        if (!mounted) return;
        setState(() {
          if (selected) {
            _selectedSubjects.add(subject);
          } else if (_selectedSubjects.length > 1) {
            // Always keep at least one subject selected so the question
            // pool can never end up empty.
            _selectedSubjects.remove(subject);
          }
        });
      },
    );
  }

  Widget _buildGameUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final keypadHeight = (constraints.maxHeight * 0.31).clamp(210.0, 320.0);
        return Column(
          children: [
            _card(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score: $score', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('Level: $level', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  HeartsDisplay(
          hearts: hearts,
          maxHearts: gameDifficultyModeHearts(_selectedMode),
        ),
                ],
              ),
            ),
            if (gameDifficultyModeHasTimer(_selectedMode)) ...[
              const SizedBox(height: 10),
              GameTimer(
                key: timerKey,
                seconds: timeLimit,
                isPaused: () => isGameOver,
                onTimeUp: _handleTimeout,
                showBar: true,
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _card(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              question.topic,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            question.instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (question.hour != null && question.minute != null) ...[
                            SizedBox(
                              height: width < 390 ? 150 : 180,
                              child: _AnalogExamClock(
                                hour: question.hour!,
                                minute: question.minute!,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            question.prompt,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        children: [
                          const Text(
                            'Your Answer',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _inkColor, width: 2),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                input.isEmpty ? 'Type here' : input,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: keypadHeight,
              child: _ExamKeypad(
                disabled: isGameOver,
                onTap: appendInput,
                onClear: clearInput,
                onSubmit: submitInput,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExamKeypad extends StatelessWidget {
  final bool disabled;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _ExamKeypad({
    required this.disabled,
    required this.onTap,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3', '/', '.'],
      ['4', '5', '6', ':', '-'],
      ['7', '8', '9', 'space', '⌫'],
      ['Delete', '0', 'Enter'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.96;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.24;
        final desktop = isDesktopLayout(width);
        final padding = desktop
            ? (width * 0.009).clamp(6.0, 10.0).toDouble()
            : (width * 0.014).clamp(6.0, 12.0).toDouble();
        final spacing = desktop
            ? (width * 0.007).clamp(3.0, 6.0).toDouble()
            : (width * 0.010).clamp(3.0, 7.0).toDouble();
        final actionGap = (spacing * 5.0).clamp(24.0, 42.0).toDouble();
        final contentWidth = width - padding * 2;
        final keyWidth = desktop
            ? ((contentWidth - spacing * 4) / 5).clamp(38.0, 176.0).toDouble()
            : ((contentWidth - spacing * 4) / 5).clamp(38.0, 142.0).toDouble();
        final keyHeight = desktop
            ? ((height - padding * 2 - spacing * 2 - actionGap) / rows.length)
                .clamp(28.0, 72.0)
                .toDouble()
            : ((height - padding * 2 - spacing * 2 - actionGap) / rows.length)
                .clamp(28.0, 58.0)
                .toDouble();
        final fontSize = desktop
            ? (min(keyWidth, keyHeight) * 0.5).clamp(18.0, 34.0).toDouble()
            : (min(keyWidth, keyHeight) * 0.43).clamp(14.0, 27.0).toDouble();
        final radius = desktop
            ? (min(keyWidth, keyHeight) * 0.14).clamp(6.0, 10.0).toDouble()
            : (min(keyWidth, keyHeight) * 0.22).clamp(8.0, 16.0).toDouble();

        return Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Container(
          width: double.infinity,
          height: height,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(desktop ? 12 : 22),
            border: Border.all(color: const Color(0x1F000000), width: 1.3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < rows.length; r++) ...[
                    if (r == rows.length - 1)
                      SizedBox(
                        width: contentWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _keyButton(
                              context,
                              label: 'Delete',
                              width: keyWidth * 1.35,
                              height: keyHeight,
                              fontSize: fontSize * 0.78,
                              radius: radius,
                              onPressed: disabled ? null : onClear,
                            ),
                            _keyButton(
                              context,
                              label: '0',
                              width: keyWidth,
                              height: keyHeight,
                              fontSize: fontSize,
                              radius: radius,
                              onPressed: disabled ? null : () => onTap('0'),
                            ),
                            _keyButton(
                              context,
                              label: 'Enter',
                              width: keyWidth * 1.35,
                              height: keyHeight,
                              fontSize: fontSize * 0.78,
                              radius: radius,
                              onPressed: disabled ? null : onSubmit,
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var c = 0; c < rows[r].length; c++) ...[
                            _keyButton(
                              context,
                              label: rows[r][c],
                              width: keyWidth,
                              height: keyHeight,
                              fontSize: rows[r][c] == 'space'
                                  ? fontSize * 0.78
                                  : fontSize,
                              radius: radius,
                              onPressed: disabled ? null : _actionFor(rows[r][c]),
                            ),
                            if (c != rows[r].length - 1) SizedBox(width: spacing),
                          ],
                        ],
                      ),
                    if (r != rows.length - 1)
                      SizedBox(height: r == rows.length - 2 ? actionGap : spacing),
                  ],
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (disabled) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      onTap('backspace');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      onSubmit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      onTap('space');
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && _examAllowedKey.hasMatch(char)) {
      onTap(char);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  VoidCallback _actionFor(String key) {
    if (key == 'Delete') return onClear;
    if (key == 'Enter') return onSubmit;
    if (key == '⌫') return () => onTap('backspace');
    if (key == 'space') return () => onTap('space');
    return () => onTap(key);
  }

  Widget _keyButton(
    BuildContext context, {
    required String label,
    required double width,
    required double height,
    required double fontSize,
    required double radius,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(width, height),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _AnalogExamClock extends StatelessWidget {
  final int hour;
  final int minute;

  const _AnalogExamClock({required this.hour, required this.minute});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnalogExamClockPainter(hour: hour, minute: minute),
      child: const SizedBox.expand(),
    );
  }
}

class _AnalogExamClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  const _AnalogExamClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final borderPaint = Paint()
      ..color = const Color(0xFF2F5233)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final markPaint = Paint()
      ..color = const Color(0xFF2F5233)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final outer = Offset(center.dx + cos(angle) * (radius - 6), center.dy + sin(angle) * (radius - 6));
      final inner = Offset(center.dx + cos(angle) * (radius - 16), center.dy + sin(angle) * (radius - 16));
      canvas.drawLine(inner, outer, markPaint);
    }

    final minuteAngle = (minute * 6 - 90) * pi / 180;
    final hourAngle = (((hour % 12) * 30) + minute * 0.5 - 90) * pi / 180;

    final handPaint = Paint()
      ..color = const Color(0xFF2F5233)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final minutePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(center.dx + cos(hourAngle) * (radius * 0.48), center.dy + sin(hourAngle) * (radius * 0.48)),
      handPaint,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + cos(minuteAngle) * (radius * 0.72), center.dy + sin(minuteAngle) * (radius * 0.72)),
      minutePaint,
    );
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF2F5233));
  }

  @override
  bool shouldRepaint(covariant _AnalogExamClockPainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }
}

/// Compiled once. These ran on every keypress and on every frame that
/// formatted a number.
final RegExp _examTrailingZero = RegExp(r'0$');
final RegExp _examWhitespaceRun = RegExp(r'\s+');
final RegExp _examAllowedKey = RegExp(r'^[0-9./:-]$');
