import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/game_logger.dart';
import '../services/leaderboard_service.dart';
import '../services/leave_attempt_logger.dart';
import '../services/sound_service.dart';
import '../widgets/animated_shape_background.dart';
import '../widgets/app_brightness_overlay.dart';
import '../widgets/correct_splash.dart';
import '../widgets/game_over_popup.dart';
import '../widgets/game_timer.dart';
import '../widgets/hearts_display.dart';
import '../widgets/incorrect_splash.dart';
import '../widgets/leave_warning_overlay.dart';
import '../widgets/level_up_popup.dart';

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

class ExamGame extends StatefulWidget {
  final ExamDifficulty difficulty;

  const ExamGame({super.key, required this.difficulty});

  @override
  State<ExamGame> createState() => _ExamGameState();
}

class _ExamQuestion {
  final String topic;
  final String instruction;
  final String prompt;
  final List<String> acceptedAnswers;
  final int? hour;
  final int? minute;

  const _ExamQuestion({
    required this.topic,
    required this.instruction,
    required this.prompt,
    required this.acceptedAnswers,
    this.hour,
    this.minute,
  });
}

class _ExamGameState extends State<ExamGame> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1450);

  final Random _random = Random();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;
  bool _isSavingScore = false;

  int score = 0;
  int level = 1;
  int hearts = 3;
  int timeLimit = 18;
  String input = '';
  _ExamQuestion question = const _ExamQuestion(
    topic: 'Addition',
    instruction: 'Solve the addition problem.',
    prompt: '8 + 7 = ___',
    acceptedAnswers: ['15'],
  );
  Key timerKey = UniqueKey();

  String get _difficultyName => _examDifficultyName(widget.difficulty);
  String get _gameName => '$_difficultyName Exam';

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    GameLogger.endSession();
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  void startGame() {
    GameLogger.startNewSession(_gameName);
    setState(() {
      hasStarted = true;
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      _isSavingScore = false;
      score = 0;
      level = 1;
      hearts = 3;
      input = '';
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  int _rand(int min, int max) => min + _random.nextInt(max - min + 1);

  void generateQuestion() {
    final builders = switch (widget.difficulty) {
      ExamDifficulty.easy => <_ExamQuestion Function()>[
          _additionQuestion,
          _subtractionQuestion,
          _romanQuestion,
          _placeValueQuestion,
        ],
      ExamDifficulty.medium => <_ExamQuestion Function()>[
          _multiplicationQuestion,
          _divisionQuestion,
          _roundingQuestion,
          _analogClockQuestion,
        ],
      ExamDifficulty.hard => <_ExamQuestion Function()>[
          _orderOperationsQuestion,
          _fractionQuestion,
          _measurementQuestion,
        ],
    };

    final next = builders[_random.nextInt(builders.length)]();
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
    return s.endsWith('00') ? value.toStringAsFixed(0) : s.replaceFirst(RegExp(r'0$'), '');
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
        .replaceAll(RegExp(r'\s+'), ' ')
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

    if (_isCorrectAnswer(input)) {
      SoundService().playCorrectSound();
      final nextScore = score + 10 + ((level - 1) * 2);
      final nextLevel = (nextScore ~/ 50) + 1;
      final didLevelUp = nextLevel > level;

      setState(() {
        score = nextScore;
        if (didLevelUp) level = nextLevel;
        showCorrectSplash = true;
        isGameOver = true;
      });

      Future.delayed(_correctFeedbackDuration, () {
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

    _handleIncorrect(input);
  }

  void _handleTimeout() {
    if (isGameOver) return;
    _handleIncorrect('Time out');
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

    Future.delayed(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() => showIncorrectSplash = false);
      showGameOverScreen(incorrectAnswer);
    });
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
    try {
      await LeaveAttemptLogger.logAttempt(
        gameName: _gameName,
        reason: 'player_pressed_back_while_playing',
        source: 'back_button',
        details: {
          'score': score,
          'level': level,
        },
      );
    } catch (error) {
      debugPrint('Leave attempt log failed: $error');
    }
    await saveScore();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> saveScore() async {
    if (_isSavingScore) return;
    _isSavingScore = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final highscoreKey = '${_difficultyName.toLowerCase()}_exam_highscore';

      await GameLogger.logGame(gameName: _gameName, score: score);

      final snapshot = await userRef.get();
      final previousHighscore = snapshot.data()?[highscoreKey];
      final currentHighscore = previousHighscore is num ? previousHighscore.toInt() : 0;

      await userRef.set({
        '${_difficultyName.toLowerCase()}_exam_last_score': score,
        '${_difficultyName.toLowerCase()}_exam_last_level': level,
        '${_difficultyName.toLowerCase()}_exam_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) highscoreKey: score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(gameName: _gameName, newScore: score);
      }
    } catch (error) {
      debugPrint('Error in saveScore ($_gameName): $error');
    } finally {
      _isSavingScore = false;
    }
  }

  Future<void> _onBackPressed() async {
    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    SoundService().playButtonSoundNow();
    if (hasStarted && score > 0) {
      await saveScore();
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text('$_difficultyName Exam'),
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
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: _inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(bodyColor: _inkColor, displayColor: _inkColor),
      colorScheme: base.colorScheme.copyWith(
        primary: _accentColor,
        secondary: _accentColor,
        surface: _panelColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  String _topicSummary() {
    switch (widget.difficulty) {
      case ExamDifficulty.easy:
        return 'Addition • Subtraction • Roman Numerals • Place Value';
      case ExamDifficulty.medium:
        return 'Multiplication • Division • Rounding Numbers • Analog Clock';
      case ExamDifficulty.hard:
        return 'Order of Operations • Fractions • Measurements';
    }
  }

  Widget _buildStartPanel() {
    return Center(
      child: SingleChildScrollView(
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_difficultyName Exam',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Questions are randomized every round.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _inkColor.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Text(
                  _topicSummary(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: startGame,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start $_difficultyName Exam'),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  HeartsDisplay(hearts: hearts),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GameTimer(
              key: timerKey,
              seconds: timeLimit,
              isPaused: () => isGameOver,
              onTimeUp: _handleTimeout,
              showBar: true,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
    final rows = const [
      ['1', '2', '3', '/', '.'],
      ['4', '5', '6', ':', '-'],
      ['7', '8', '9', 'space', '⌫'],
      ['C', '0', 'Submit'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.96;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.24;
        final padding = (width * 0.014).clamp(6.0, 12.0).toDouble();
        final spacing = (width * 0.010).clamp(3.0, 7.0).toDouble();
        final contentWidth = width - padding * 2;
        final keyWidth = ((contentWidth - spacing * 4) / 5).clamp(38.0, 142.0).toDouble();
        final keyHeight = ((height - padding * 2 - spacing * (rows.length - 1)) / rows.length)
            .clamp(28.0, 58.0)
            .toDouble();
        final fontSize = (min(keyWidth, keyHeight) * 0.43).clamp(14.0, 27.0).toDouble();

        return Container(
          width: double.infinity,
          height: height,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(22),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var c = 0; c < rows[r].length; c++) ...[
                          _keyButton(
                            context,
                            label: rows[r][c],
                            width: rows[r][c] == 'Submit' ? keyWidth * 2.05 : keyWidth,
                            height: keyHeight,
                            fontSize: rows[r][c] == 'Submit' || rows[r][c] == 'space'
                                ? fontSize * 0.78
                                : fontSize,
                            onPressed: disabled ? null : _actionFor(rows[r][c]),
                          ),
                          if (c != rows[r].length - 1) SizedBox(width: spacing),
                        ],
                      ],
                    ),
                    if (r != rows.length - 1) SizedBox(height: spacing),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  VoidCallback _actionFor(String key) {
    if (key == 'C') return onClear;
    if (key == 'Submit') return onSubmit;
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
            borderRadius: BorderRadius.circular((height * 0.22).clamp(8.0, 16.0).toDouble()),
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
