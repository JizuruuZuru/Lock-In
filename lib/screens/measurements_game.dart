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

enum MeasurementMode { lengths, weights, capacities, temperatures, random }

enum _MeasurementVisual { none, ruler, scale, cup, thermometer, weather }

class _MeasurementQuestion {
  final MeasurementMode mode;
  final String category;
  final String instruction;
  final String expression;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final _MeasurementVisual visual;
  final double? visualValue;
  final String? hint;

  const _MeasurementQuestion({
    required this.mode,
    required this.category,
    required this.instruction,
    required this.expression,
    required this.correctAnswer,
    required this.acceptedAnswers,
    this.visual = _MeasurementVisual.none,
    this.visualValue,
    this.hint,
  });
}


class _MeasurementWorksheet {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> facts;
  final List<String> examples;
  final String tip;

  const _MeasurementWorksheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.facts,
    required this.examples,
    required this.tip,
  });
}

class MeasurementsGame extends StatefulWidget {
  const MeasurementsGame({super.key});

  @override
  State<MeasurementsGame> createState() => _MeasurementsGameState();
}

class _MeasurementsGameState extends State<MeasurementsGame> {
  static const String _gameName = 'Measurements';
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1500);

  final Random _random = Random();

  MeasurementMode? selectedMode;
  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;
  bool _isSavingScore = false;

  int score = 0;
  int level = 1;
  int hearts = 3;
  int timeLimit = 20;
  String input = '';
  Key timerKey = UniqueKey();

  _MeasurementQuestion currentQuestion = const _MeasurementQuestion(
    mode: MeasurementMode.lengths,
    category: 'Lengths',
    instruction: 'Convert between inches, feet, and yards.',
    expression: '30 ft = ___ yd',
    correctAnswer: '10',
    acceptedAnswers: ['10'],
  );

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

  String _modeTitle(MeasurementMode mode) {
    switch (mode) {
      case MeasurementMode.lengths:
        return 'Lengths';
      case MeasurementMode.weights:
        return 'Weights';
      case MeasurementMode.capacities:
        return 'Capacities';
      case MeasurementMode.temperatures:
        return 'Temperatures';
      case MeasurementMode.random:
        return 'Random';
    }
  }

  IconData _modeIcon(MeasurementMode mode) {
    switch (mode) {
      case MeasurementMode.lengths:
        return Icons.straighten_rounded;
      case MeasurementMode.weights:
        return Icons.monitor_weight_rounded;
      case MeasurementMode.capacities:
        return Icons.local_drink_rounded;
      case MeasurementMode.temperatures:
        return Icons.thermostat_rounded;
      case MeasurementMode.random:
        return Icons.shuffle_rounded;
    }
  }

  String _modeSubtitle(MeasurementMode mode) {
    switch (mode) {
      case MeasurementMode.lengths:
        return 'Inches, feet, yards, miles, cm, mm, m, km';
      case MeasurementMode.weights:
        return 'Ounces, pounds, grams, and kilograms';
      case MeasurementMode.capacities:
        return 'Cups, pints, quarts, gallons, liters, milliliters';
      case MeasurementMode.temperatures:
        return 'Thermometers, Fahrenheit, Celsius, and weather';
      case MeasurementMode.random:
        return 'Mixed questions from all measurement modes';
    }
  }

  List<MeasurementMode> get _modes => const [
        MeasurementMode.lengths,
        MeasurementMode.weights,
        MeasurementMode.capacities,
        MeasurementMode.temperatures,
        MeasurementMode.random,
      ];

  void _selectMode(MeasurementMode mode) {
    SoundService().playButtonSoundNow();
    setState(() => selectedMode = mode);
  }

  void startGame() {
    if (selectedMode == null) return;
    GameLogger.startNewSession('$_gameName - ${_modeTitle(selectedMode!)}');
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
      timeLimit = 20;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  void generateQuestion() {
    final mode = selectedMode ?? MeasurementMode.random;
    final activeMode = mode == MeasurementMode.random
        ? _modes.where((m) => m != MeasurementMode.random).toList()[
            _random.nextInt(_modes.length - 1)]
        : mode;

    _MeasurementQuestion nextQuestion;
    switch (activeMode) {
      case MeasurementMode.lengths:
        nextQuestion = _lengthQuestion();
        break;
      case MeasurementMode.weights:
        nextQuestion = _weightQuestion();
        break;
      case MeasurementMode.capacities:
        nextQuestion = _capacityQuestion();
        break;
      case MeasurementMode.temperatures:
        nextQuestion = _temperatureQuestion();
        break;
      case MeasurementMode.random:
        nextQuestion = _lengthQuestion();
        break;
    }

    setState(() {
      currentQuestion = nextQuestion;
      input = '';
      timeLimit = _timeLimitForLevel();
      timerKey = UniqueKey();
    });
  }

  _MeasurementQuestion _lengthQuestion() {
    final unlocked = <int>[0, 1, 2];
    if (level >= 2) unlocked.addAll([3, 4]);
    if (level >= 3) unlocked.addAll([5, 6]);
    final type = unlocked[_random.nextInt(unlocked.length)];

    switch (type) {
      case 0:
        final yd = _random.nextInt(14) + 2;
        final ft = yd * 3;
        return _q(
          MeasurementMode.lengths,
          'Lengths',
          'Convert between inches, feet, and yards.',
          '$ft ft = ___ yd',
          yd.toString(),
        );
      case 1:
        final yards = _random.nextInt(10) + 2;
        final rem = _random.nextInt(2) + 1;
        final ft = yards * 3 + rem;
        return _q(
          MeasurementMode.lengths,
          'Lengths',
          'Convert between inches, feet, and yards. Enter: yd ft',
          '$ft ft = ___ yd ___ ft',
          '$yards $rem',
          accepted: ['$yards $rem', '${yards}yd${rem}ft', '$yards yd $rem ft'],
          hint: 'Use SPACE between the two numbers. Example: 10 2',
        );
      case 2:
        final cm = (_random.nextInt(18) + 2) * 10;
        final mm = cm * 10;
        return _q(
          MeasurementMode.lengths,
          'Metric Lengths',
          'Convert between centimeters and millimeters.',
          '$mm mm = ___ cm',
          cm.toString(),
        );
      case 3:
        final mm = _random.nextInt(91) + 10;
        final answer = _cleanDecimal(mm / 10);
        return _q(
          MeasurementMode.lengths,
          'Metric Lengths',
          'Convert millimeters to centimeters with decimals.',
          '$mm mm = ___ cm',
          answer,
        );
      case 4:
        final meters = (_random.nextInt(9) + 2) * 10;
        final cm = meters * 100;
        return _q(
          MeasurementMode.lengths,
          'Metric Lengths',
          'Convert between meters, centimeters and millimeters.',
          '${_comma(cm)} cm = ___ m',
          meters.toString(),
        );
      case 5:
        final yd = _random.nextInt(8) + 2;
        return _q(
          MeasurementMode.lengths,
          'Customary Lengths',
          'Convert yards to feet.',
          '$yd yd = ___ ft',
          (yd * 3).toString(),
        );
      default:
        final km = _random.nextInt(7) + 1;
        return _q(
          MeasurementMode.lengths,
          'Metric Lengths',
          'Convert kilometers to meters.',
          '$km km = ___ m',
          (km * 1000).toString(),
        );
    }
  }

  _MeasurementQuestion _weightQuestion() {
    final unlocked = <int>[0, 1, 2];
    if (level >= 2) unlocked.addAll([3, 4]);
    final type = unlocked[_random.nextInt(unlocked.length)];

    switch (type) {
      case 0:
        final lb = _random.nextInt(12) + 2;
        return _q(
          MeasurementMode.weights,
          'Weights',
          'Convert ounces and pounds.',
          '$lb lb = ___ oz',
          (lb * 16).toString(),
        );
      case 1:
        final pounds = _random.nextInt(7) + 2;
        final oz = _random.nextInt(15) + 1;
        final total = pounds * 16 + oz;
        return _q(
          MeasurementMode.weights,
          'Weights',
          'Convert ounces and pounds. Enter: lb oz',
          '$total oz = ___ lb ___ oz',
          '$pounds $oz',
          accepted: ['$pounds $oz', '${pounds}lb${oz}oz', '$pounds lb $oz oz'],
          hint: 'Use SPACE between the two numbers. Example: 5 3',
        );
      case 2:
        final kg = _random.nextInt(15) + 1;
        return _q(
          MeasurementMode.weights,
          'Metric Weights',
          'Convert kilograms and grams.',
          '$kg kg = ___ g',
          (kg * 1000).toString(),
        );
      case 3:
        final pounds = _random.nextInt(10) + 2;
        final ounces = _random.nextInt(15) + 1;
        final total = pounds * 16 + ounces;
        return _q(
          MeasurementMode.weights,
          'Customary Weights',
          'Convert pounds and ounces to ounces.',
          '$pounds lb $ounces oz = ___ oz',
          total.toString(),
        );
      default:
        final grams = (_random.nextInt(18) + 2) * 500;
        final kg = _cleanDecimal(grams / 1000);
        return _q(
          MeasurementMode.weights,
          'Metric Weights',
          'Convert grams to kilograms.',
          '$grams g = ___ kg',
          kg,
        );
    }
  }

  _MeasurementQuestion _capacityQuestion() {
    final unlocked = <int>[0, 1, 2];
    if (level >= 2) unlocked.addAll([3, 4]);
    final type = unlocked[_random.nextInt(unlocked.length)];

    switch (type) {
      case 0:
        final gal = _random.nextInt(8) + 2;
        final qt = gal * 4;
        return _q(
          MeasurementMode.capacities,
          'Capacities',
          'Convert cups, pints, quarts, and gallons.',
          '$qt qt = ___ gal',
          gal.toString(),
        );
      case 1:
        final quarts = _random.nextInt(5) + 1;
        final cups = _random.nextInt(3) + 1;
        final totalCups = quarts * 4 + cups;
        return _q(
          MeasurementMode.capacities,
          'Capacities',
          'Convert cups to quarts and cups. Enter: qt C',
          '$totalCups C = ___ qt ___ C',
          '$quarts $cups',
          accepted: ['$quarts $cups', '${quarts}qt${cups}c', '$quarts qt $cups c'],
          hint: 'Use SPACE between the two numbers. Example: 3 2',
        );
      case 2:
        final liters = _random.nextInt(8) + 1;
        return _q(
          MeasurementMode.capacities,
          'Metric Capacities',
          'Convert liters and milliliters.',
          '$liters L = ___ mL',
          (liters * 1000).toString(),
        );
      case 3:
        final pints = _random.nextInt(6) + 2;
        return _q(
          MeasurementMode.capacities,
          'Customary Capacities',
          'Convert pints to cups.',
          '$pints pt = ___ C',
          (pints * 2).toString(),
        );
      default:
        final ml = (_random.nextInt(9) + 1) * 250;
        final liters = _cleanDecimal(ml / 1000);
        return _q(
          MeasurementMode.capacities,
          'Metric Capacities',
          'Convert milliliters to liters.',
          '$ml mL = ___ L',
          liters,
        );
    }
  }

  _MeasurementQuestion _temperatureQuestion() {
    final unlocked = <int>[0, 1, 2, 3];
    final type = unlocked[_random.nextInt(unlocked.length)];

    switch (type) {
      case 0:
        final morning = (_random.nextInt(5) + 4) * 10;
        final afternoon = morning + (_random.nextInt(3) + 1) * 5;
        return _q(
          MeasurementMode.temperatures,
          'Temperatures',
          'Find the Fahrenheit temperature increase.',
          'Morning: $morning°F, Afternoon: $afternoon°F. Increase = ___°F',
          (afternoon - morning).toString(),
          hint: 'Enter the number only.',
        );
      case 1:
        final first = (_random.nextInt(5) + 2) * 5;
        final second = first + (_random.nextInt(4) + 1) * 3;
        return _q(
          MeasurementMode.temperatures,
          'Temperatures',
          'Find the Celsius temperature difference.',
          '$second°C - $first°C = ___°C',
          (second - first).toString(),
          hint: 'Enter the number only.',
        );
      case 2:
        final cold = _random.nextInt(12) + 5;
        final warm = cold + _random.nextInt(12) + 8;
        return _q(
          MeasurementMode.temperatures,
          'Weather and Temperature',
          'Find the temperature difference.',
          'Morning: $cold°C, Afternoon: $warm°C. Difference = ___°C',
          (warm - cold).toString(),
        );
      default:
        return _q(
          MeasurementMode.temperatures,
          'Weather and Temperature',
          'Choose the warmer temperature.',
          'Which is warmer? 30°C or 20°C',
          '30',
          accepted: ['30', '30c', '30 c', '30°c'],
        );
    }
  }

  _MeasurementQuestion _q(
    MeasurementMode mode,
    String category,
    String instruction,
    String expression,
    String answer, {
    List<String>? accepted,
    _MeasurementVisual visual = _MeasurementVisual.none,
    double? visualValue,
    String? hint,
  }) {
    final allAccepted = <String>{answer, ...?accepted};
    return _MeasurementQuestion(
      mode: mode,
      category: category,
      instruction: instruction,
      expression: expression,
      correctAnswer: answer,
      acceptedAnswers: allAccepted.toList(),
      visual: visual,
      visualValue: visualValue,
      hint: hint,
    );
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 24;
    if (level <= 4) return 22;
    if (level <= 6) return 20;
    return 18;
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    if (input.length >= 18 && value != 'BACK') return;

    setState(() {
      if (value == 'BACK') {
        if (input.isNotEmpty) input = input.substring(0, input.length - 1);
      } else if (value == 'SPACE') {
        if (input.isNotEmpty && !input.endsWith(' ')) input += ' ';
      } else if (value == '.') {
        final lastToken = input.split(' ').last;
        if (!lastToken.contains('.')) input += value;
      } else {
        input += value;
      }
    });
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

    _handleIncorrect(input.trim());
  }

  bool _isCorrectAnswer(String value) {
    final normalizedInput = _normalizeAnswer(value);
    return currentQuestion.acceptedAnswers
        .map(_normalizeAnswer)
        .contains(normalizedInput);
  }

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .replaceAll(',', '')
        .replaceAll('°', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
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
      debugPrint('Error saving Measurements score: $error');
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
        message:
            'Nice measurement work!\nMore conversion, reading, and mixed measurement challenges are unlocked.',
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
        correctAnswer: currentQuestion.correctAnswer,
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
        gameName: selectedMode == null ? _gameName : '$_gameName - ${_modeTitle(selectedMode!)}',
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
      final gameLabel = selectedMode == null
          ? _gameName
          : '$_gameName - ${_modeTitle(selectedMode!)}';

      await GameLogger.logGame(gameName: gameLabel, score: score);

      final snapshot = await userRef.get();
      final previousHighscore = snapshot.data()?['measurements_highscore'];
      final currentHighscore = previousHighscore is num
          ? previousHighscore.toInt()
          : 0;

      await userRef.set({
        'measurements_last_score': score,
        'measurements_last_level': level,
        'measurements_last_mode': selectedMode == null ? null : _modeTitle(selectedMode!),
        'measurements_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) 'measurements_highscore': score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(gameName: gameLabel, newScore: score);
      }
    } catch (error) {
      debugPrint('Error in saveScore (Measurements): $error');
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Measurements'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
        ),
        body: _buildBackground(
          child: Stack(
            children: [
              AppBrightnessOverlay(
                child: hasStarted ? _buildGameView() : _buildModeView(),
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
              if (_showExitConfirmation)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Leave game?',
                    message:
                        'Your current Measurements score will be saved before leaving.',
                    okText: 'Stay',
                    backText: 'Leave',
                    isBusy: _isSavingScore,
                    onOk: _cancelExitConfirmation,
                    onBack: _confirmExitFromBack,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeView() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final chosen = selectedMode;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 28 : 16,
              vertical: 16,
            ),
            children: [
              _card(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Measurements',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review a worksheet example first, then choose a mode and play.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                childAspectRatio: isWide ? 2.15 : 2.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final mode in _modes) _modeCard(mode),
                ],
              ),
              const SizedBox(height: 16),
              _worksheetPreview(chosen ?? MeasurementMode.random),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: chosen == null
                    ? null
                    : () {
                        SoundService().playButtonSoundNow();
                        startGame();
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(chosen == null
                    ? 'Choose a Mode First'
                    : 'Start ${_modeTitle(chosen)}'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _modeCard(MeasurementMode mode) {
    final active = selectedMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _selectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F5E9) : _panelColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? _accentColor : _inkColor,
            width: active ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332C3550),
              offset: Offset(4, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _inkColor, width: 1.6),
              ),
              child: Icon(_modeIcon(mode), color: _accentColor, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _modeTitle(mode),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _modeSubtitle(mode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _worksheetPreview(MeasurementMode mode) {
    final items = _worksheetItems(mode);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: _accentColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_modeTitle(mode)} worksheet examples',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the worksheet button to review units, examples, and conversions. Swipe left or right to change worksheets.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _inkColor.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWorksheetViewer(
                initialPage: _worksheetInitialPage(mode),
              ),
              icon: const Icon(Icons.swipe_rounded),
              label: const Text('Open Swipe Worksheets'),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _inkColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }


  List<String> _worksheetItems(MeasurementMode mode) {
    switch (mode) {
      case MeasurementMode.lengths:
        return const [
          'Units of length (customary): inches, feet, yards, miles',
          'Units of length (metric): mm, cm, m, km',
          '30 ft = ___ yd  →  10 yd',
          '80 mm = ___ cm  →  8 cm',
          '8,000 cm = ___ m  →  80 m',
        ];
      case MeasurementMode.weights:
        return const [
          'Units of weight (customary): ounces and pounds',
          'Units of weight (metric): grams and kilograms',
          '6 lb = ___ oz  →  96 oz',
          '81 oz = ___ lb ___ oz  →  5 lb 1 oz',
          '10 kg = ___ g  →  10,000 g',
        ];
      case MeasurementMode.capacities:
        return const [
          'Units of capacity: cups, pints, quarts, gallons',
          'Metric capacity: milliliters and liters',
          '28 qt = ___ gal  →  7 gal',
          '14 C = ___ qt ___ C  →  3 qt 2 C',
          '2 L = ___ mL  →  2,000 mL',
        ];
      case MeasurementMode.temperatures:
        return const [
          'Read the thermometer: 70°F',
          'Morning 18°C and afternoon 29°C: difference = 11°C',
          'Which is warmer? 30°C or 20°C → 30°C',
        ];
      case MeasurementMode.random:
        return const [
          'Length: 30 ft = 10 yd',
          'Weight: 6 lb = 96 oz',
          'Capacity: 2 L = 2,000 mL',
          'Temperature: read a thermometer or compare weather temperatures',
        ];
    }
  }

  int _worksheetInitialPage(MeasurementMode mode) {
    switch (mode) {
      case MeasurementMode.lengths:
        return 0;
      case MeasurementMode.weights:
        return 1;
      case MeasurementMode.capacities:
        return 0;
      case MeasurementMode.temperatures:
        return 0;
      case MeasurementMode.random:
        return 0;
    }
  }

  List<_MeasurementWorksheet> get _measurementWorksheets => const [
        _MeasurementWorksheet(
          title: 'Units of Length',
          subtitle: 'Customary: inches, feet, yards, miles',
          icon: Icons.straighten_rounded,
          facts: [
            '12 inches = 1 foot',
            '3 feet = 1 yard',
            '1,760 yards = 1 mile',
            '5,280 feet = 1 mile',
          ],
          examples: [
            '30 ft = ___ yd\n30 ÷ 3 = 10, so the answer is 10 yd.',
            '32 ft = ___ yd ___ ft\n32 ÷ 3 = 10 remainder 2, so the answer is 10 yd 2 ft.',
            '2 mi = ___ ft\n2 × 5,280 = 10,560 ft.',
          ],
          tip: 'For smaller to larger units, divide. For larger to smaller units, multiply.',
        ),
        _MeasurementWorksheet(
          title: 'Units of Weight',
          subtitle: 'Customary: ounces and pounds',
          icon: Icons.monitor_weight_rounded,
          facts: [
            '16 ounces = 1 pound',
            '1 pound = 16 ounces',
          ],
          examples: [
            '6 lb = ___ oz\n6 × 16 = 96, so the answer is 96 oz.',
            '81 oz = ___ lb ___ oz\n81 ÷ 16 = 5 remainder 1, so the answer is 5 lb 1 oz.',
            '3 lb 4 oz = ___ oz\n3 × 16 + 4 = 52 oz.',
          ],
          tip: 'Use 16 as the conversion number between pounds and ounces.',
        ),
        _MeasurementWorksheet(
          title: 'Units of Weight',
          subtitle: 'Metric: grams and kilograms',
          icon: Icons.scale_rounded,
          facts: [
            '1 kilogram = 1,000 grams',
            '1,000 grams = 1 kilogram',
          ],
          examples: [
            '10 kg = ___ g\n10 × 1,000 = 10,000 g.',
            '2,500 g = ___ kg\n2,500 ÷ 1,000 = 2.5 kg.',
            '3 kg 250 g = ___ g\n3,000 + 250 = 3,250 g.',
          ],
          tip: 'Metric weight is based on 1,000. Move between kg and g using ×1,000 or ÷1,000.',
        ),
        _MeasurementWorksheet(
          title: 'Units of Length',
          subtitle: 'Metric: cm, m, km',
          icon: Icons.architecture_rounded,
          facts: [
            '10 millimeters = 1 centimeter',
            '100 centimeters = 1 meter',
            '1,000 meters = 1 kilometer',
            '100,000 centimeters = 1 kilometer',
          ],
          examples: [
            '80 mm = ___ cm\n80 ÷ 10 = 8 cm.',
            '8,000 cm = ___ m\n8,000 ÷ 100 = 80 m.',
            '3 km = ___ m\n3 × 1,000 = 3,000 m.',
          ],
          tip: 'Metric length uses powers of 10, so conversions often move the decimal point.',
        ),
      ];

  Future<void> _openWorksheetViewer({int initialPage = 0}) async {
    SoundService().playButtonSoundNow();
    final sheets = _measurementWorksheets;
    final safeInitial = initialPage.clamp(0, sheets.length - 1).toInt();
    final controller = PageController(initialPage: safeInitial);
    var currentPage = safeInitial;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final size = MediaQuery.sizeOf(context);
            final dialogWidth = min(size.width - 28, 760.0).toDouble();
            final dialogHeight = min(size.height * 0.86, 720.0).toDouble();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: _panelColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _inkColor, width: 2.6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332C3550),
                      offset: Offset(7, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Measurement Worksheets',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Swipe left or right to change the worksheet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            SoundService().playButtonSoundNow();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        onPageChanged: (index) {
                          SoundService().playButtonSoundNow();
                          setDialogState(() => currentPage = index);
                        },
                        itemCount: sheets.length,
                        itemBuilder: (context, index) {
                          return _worksheetPage(sheets[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _worksheetArrowButton(
                          icon: Icons.chevron_left_rounded,
                          enabled: currentPage > 0,
                          onTap: () {
                            controller.previousPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < sheets.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: i == currentPage ? 24 : 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: i == currentPage
                                        ? _accentColor
                                        : _inkColor.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _worksheetArrowButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: currentPage < sheets.length - 1,
                          onTap: () {
                            controller.nextPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Widget _worksheetPage(_MeasurementWorksheet sheet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor.withValues(alpha: 0.45), width: 1.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 520;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sheet.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sheet.subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              _worksheetSectionTitle('Remember'),
              const SizedBox(height: 8),
              for (final fact in sheet.facts) _worksheetFact(fact),
              SizedBox(height: compact ? 8 : 14),
              _worksheetSectionTitle('Worked Examples'),
              const SizedBox(height: 8),
              for (final example in sheet.examples) _worksheetExample(example),
              SizedBox(height: compact ? 8 : 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentColor, width: 1.8),
                ),
                child: Text(
                  'Tip: ${sheet.tip}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _worksheetSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _worksheetFact(String fact) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _inkColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        fact,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _worksheetExample(String example) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _inkColor.withValues(alpha: 0.34)),
      ),
      child: Text(
        example,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _worksheetArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled
            ? () {
                SoundService().playButtonSoundNow();
                onTap();
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Icon(icon, size: 32),
      ),
    );
  }


  Widget _buildGameView() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isWide = width >= 860;
          final padWidth = min(isWide ? width * 0.42 : width * 0.96, 680.0)
              .clamp(320.0, 680.0)
              .toDouble();
          final padTarget = min(isWide ? height * 0.72 : height * 0.38, 360.0);
          final padHeight = min(max(220.0, padTarget), max(220.0, height * 0.52))
              .toDouble();

          final content = <Widget>[
            _buildQuestionPanel(),
            SizedBox(height: isWide ? 0 : 16, width: isWide ? 18 : 0),
            SizedBox(
              width: padWidth,
              height: padHeight,
              child: _MeasurementAnswerPad(
                input: input,
                isDisabled: isGameOver,
                onValueTap: appendInput,
                onClear: clearInput,
                onSubmit: submitInput,
              ),
            ),
          ];

          return Padding(
            padding: EdgeInsets.all(isWide ? 16 : 10),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: content[0]),
                      content[1],
                      content[2],
                    ],
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      content[0],
                      const SizedBox(height: 10),
                      Center(child: content[2]),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(Icons.star_rounded, 'Score', '$score'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(Icons.trending_up_rounded, 'Level', '$level'),
            ),
            const SizedBox(width: 10),
            HeartsDisplay(hearts: hearts),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_modeIcon(currentQuestion.mode), color: _accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentQuestion.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: GameTimer(
                      key: timerKey,
                      seconds: timeLimit,
                      isPaused: () => isGameOver,
                      onTimeUp: _handleTimeout,
                      showBar: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentQuestion.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _inkColor, width: 2),
                ),
                child: Text(
                  currentQuestion.expression,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentColor, width: 2),
                ),
                child: Text(
                  input.trim().isEmpty ? 'Your Answer' : input,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (currentQuestion.hint != null) ...[
                const SizedBox(height: 10),
                Text(
                  currentQuestion.hint!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _inkColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _accentColor, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _visualForQuestion() {
    switch (currentQuestion.visual) {
      case _MeasurementVisual.ruler:
        return _RulerVisual(value: currentQuestion.visualValue ?? 2.0);
      case _MeasurementVisual.scale:
        return _ScaleVisual(value: currentQuestion.visualValue ?? 25);
      case _MeasurementVisual.cup:
        return _CupVisual(value: currentQuestion.visualValue ?? 2);
      case _MeasurementVisual.thermometer:
        return _ThermometerVisual(value: currentQuestion.visualValue ?? 50);
      case _MeasurementVisual.weather:
        return const _WeatherVisual();
      case _MeasurementVisual.none:
        return const SizedBox.shrink();
    }
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
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2),
          ),
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
          kind: BackgroundShapeKind.capsule,
          alignment: Alignment.topRight,
          baseOffset: Offset(24, 76),
          drift: Offset(14, 18),
          size: 112,
          color: Color(0x33FF9800),
          borderColor: Color(0x4D2F5233),
          initialRotation: 0.18,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(36, 38),
          drift: Offset(12, 14),
          size: 126,
          color: Color(0x2E4CAF50),
          borderColor: Color(0x4D2F5233),
        ),
      ],
      child: child,
    );
  }

  String _cleanDecimal(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _comma(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _MeasurementAnswerPad extends StatelessWidget {
  final String input;
  final bool isDisabled;
  final ValueChanged<String> onValueTap;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _MeasurementAnswerPad({
    required this.input,
    required this.isDisabled,
    required this.onValueTap,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.96;
        final panelHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.30;
        final width = panelWidth.clamp(280.0, 720.0).toDouble();
        final height = panelHeight.clamp(220.0, 380.0).toDouble();
        final padding = (width * 0.020).clamp(6.0, 12.0).toDouble();
        final spacing = (width * 0.010).clamp(3.0, 7.0).toDouble();
        final rows = const [
          ['1', '2', '3', '.'],
          ['4', '5', '6', 'SPACE'],
          ['7', '8', '9', '⌫'],
          ['C', '0', '→'],
        ];
        final contentWidth = width - padding * 2;
        final keyWidth = ((contentWidth - spacing * 3) / 4).clamp(42.0, 150.0).toDouble();
        final keyHeight = ((height - padding * 2 - spacing * (rows.length - 1)) / rows.length)
            .clamp(40.0, 84.0)
            .toDouble();
        final fontSize = (min(keyWidth, keyHeight) * 0.44).clamp(15.0, 31.0).toDouble();

        return SizedBox(
          width: width,
          height: height,
          child: Container(
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
                    for (var row = 0; row < rows.length; row++) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var col = 0; col < rows[row].length; col++) ...[
                            _button(
                              rows[row][col],
                              keyWidth,
                              keyHeight,
                              fontSize,
                            ),
                            if (col != rows[row].length - 1) SizedBox(width: spacing),
                          ],
                        ],
                      ),
                      if (row != rows.length - 1) SizedBox(height: spacing),
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

  Widget _button(String label, double width, double height, double fontSize) {
    VoidCallback? action;
    String text = label;
    if (label == 'C') {
      action = onClear;
    } else if (label == '→') {
      action = onSubmit;
    } else if (label == '⌫') {
      action = () => onValueTap('BACK');
    } else if (label == 'SPACE') {
      text = 'space';
      action = () => onValueTap('SPACE');
    } else {
      action = () => onValueTap(label);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : action,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((height * 0.24).clamp(8.0, 16.0).toDouble()),
          ),
          textStyle: TextStyle(
            fontSize: label == 'SPACE' ? fontSize * 0.72 : fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}

class _RulerVisual extends StatelessWidget {
  final double value;
  const _RulerVisual({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RulerPainter(value),
      child: const SizedBox.expand(),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  _RulerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F5233)
      ..strokeWidth = 2;
    final accent = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.62;
    final startX = size.width * 0.08;
    final endX = size.width * 0.92;
    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    const divisions = 12;
    for (var i = 0; i <= divisions; i++) {
      final x = startX + (endX - startX) * i / divisions;
      final tall = i % 4 == 0;
      final h = tall ? 42.0 : (i % 2 == 0 ? 30.0 : 20.0);
      canvas.drawLine(Offset(x, y), Offset(x, y - h), paint);
    }
    final clamped = value.clamp(0.0, 3.0);
    final markerX = startX + (endX - startX) * clamped / 3.0;
    canvas.drawLine(Offset(startX, y + 18), Offset(markerX, y + 18), accent);
    canvas.drawCircle(Offset(markerX, y + 18), 7, accent);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) => oldDelegate.value != value;
}

class _ScaleVisual extends StatelessWidget {
  final double value;
  const _ScaleVisual({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScalePainter(value),
      child: const SizedBox.expand(),
    );
  }
}

class _ScalePainter extends CustomPainter {
  final double value;
  _ScalePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = min(size.width, size.height) * 0.34;
    final base = Paint()..color = const Color(0xFFE8F5E9);
    final border = Paint()
      ..color = const Color(0xFF2F5233)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, base);
    canvas.drawCircle(center, radius, border);
    final needle = Paint()
      ..color = const Color(0xFFD84315)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final angle = pi + (value.clamp(0, 75) / 75) * pi;
    final tip = Offset(center.dx + cos(angle) * radius * 0.72, center.dy + sin(angle) * radius * 0.72);
    canvas.drawLine(center, tip, needle);
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF2F5233));
  }

  @override
  bool shouldRepaint(covariant _ScalePainter oldDelegate) => oldDelegate.value != value;
}

class _CupVisual extends StatelessWidget {
  final double value;
  const _CupVisual({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CupPainter(value),
      child: const SizedBox.expand(),
    );
  }
}

class _CupPainter extends CustomPainter {
  final double value;
  _CupPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(size.width * 0.30, size.height * 0.10, size.width * 0.40, size.height * 0.78);
    final border = Paint()
      ..color = const Color(0xFF2F5233)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fill = Paint()..color = const Color(0x664CAF50);
    final amount = (value.clamp(1, 4) / 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), border);
    for (var i = 1; i <= 4; i++) {
      final y = rect.bottom - rect.height * i / 4;
      canvas.drawLine(Offset(rect.right, y), Offset(rect.right + 22, y), border);
    }
  }

  @override
  bool shouldRepaint(covariant _CupPainter oldDelegate) => oldDelegate.value != value;
}

class _ThermometerVisual extends StatelessWidget {
  final double value;
  const _ThermometerVisual({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThermometerPainter(value),
      child: const SizedBox.expand(),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  final double value;
  _ThermometerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final top = size.height * 0.10;
    final bottom = size.height * 0.82;
    final tube = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF2F5233)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final mercury = Paint()..color = const Color(0xFFD84315);
    final tubeRect = Rect.fromLTWH(centerX - 16, top, 32, bottom - top);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(18)), tube);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(18)), border);
    canvas.drawCircle(Offset(centerX, bottom + 18), 26, mercury);
    canvas.drawCircle(Offset(centerX, bottom + 18), 26, border);
    final percent = value.clamp(0, 100) / 100;
    final fillTop = bottom - (bottom - top) * percent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - 9, fillTop, 18, bottom - fillTop + 18), const Radius.circular(10)),
      mercury,
    );
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) => oldDelegate.value != value;
}

class _WeatherVisual extends StatelessWidget {
  const _WeatherVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wb_sunny_rounded, color: Color(0xFFFF9800), size: 72),
          SizedBox(width: 18),
          Icon(Icons.cloud_rounded, color: Color(0xFF78909C), size: 74),
          SizedBox(width: 18),
          Icon(Icons.thermostat_rounded, color: Color(0xFFD84315), size: 72),
        ],
      ),
    );
  }
}
