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
import '../widgets/level_up_popup.dart';
import '../widgets/leave_warning_overlay.dart';
import '../widgets/number_pad.dart';

class AnalogClockGame extends StatefulWidget {
  const AnalogClockGame({super.key});

  @override
  State<AnalogClockGame> createState() => _AnalogClockGameState();
}

class _AnalogClockGameState extends State<AnalogClockGame>
    with WidgetsBindingObserver {
  static const String _gameName = 'Analog Clock';
  static const Color _inkColor = Color(0xFF1B4965);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 850);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1500);

  final Random _random = Random();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _isSavingScore = false;
  bool _showExitConfirmation = false;

  int score = 0;
  int level = 1;
  int previousLevel = 1;
  int hearts = 3;
  int streak = 0;
  int timeLimit = 14;
  int targetHour = 12;
  int targetMinute = 0;
  String input = '';
  Key timerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService().playPageBgm(BgmPage.memory);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    GameLogger.endSession();
    WidgetsBinding.instance.removeObserver(this);
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  void startGame() {
    SoundService().playButtonSoundNow();
    GameLogger.startNewSession(_gameName);
    setState(() {
      hasStarted = true;
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      score = 0;
      level = 1;
      previousLevel = 1;
      hearts = 3;
      streak = 0;
      input = '';
      timerKey = UniqueKey();
      _isSavingScore = false;
    });
    _generateClockTime();
  }

  int _minuteStepForLevel() {
    if (level <= 1) return 60; // o'clock only
    if (level <= 2) return 30;
    if (level <= 3) return 15;
    return 5;
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 16;
    if (level <= 4) return 14;
    if (level <= 7) return 12;
    return 10;
  }

  void _generateClockTime() {
    final step = _minuteStepForLevel();
    final possibleMinutes = <int>[];
    for (int minute = 0; minute < 60; minute += step) {
      possibleMinutes.add(minute);
    }

    setState(() {
      targetHour = _random.nextInt(12) + 1;
      targetMinute = possibleMinutes[_random.nextInt(possibleMinutes.length)];
      timeLimit = _timeLimitForLevel();
      input = '';
      timerKey = UniqueKey();
    });
  }

  bool _updateLevel() {
    previousLevel = level;
    level = (score ~/ 40) + 1;
    return level > previousLevel;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _correctAnswerLabel => '$targetHour:${_two(targetMinute)}';

  String _displayInput() {
    if (input.isEmpty) return 'Your Answer';
    if (input.contains(':')) return input;
    if (input.length <= 2) return input;
    final hour = input.substring(0, input.length - 2);
    final minute = input.substring(input.length - 2);
    return '$hour:$minute';
  }

  int? _parseHourFromInput() {
    if (input.isEmpty) return null;

    if (input.contains(':')) {
      final parts = input.split(':');
      if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
        return null;
      }
      return int.tryParse(parts.first);
    }

    if (input.length < 3) return null;
    final rawHour = input.substring(0, input.length - 2);
    return int.tryParse(rawHour);
  }

  int? _parseMinuteFromInput() {
    if (input.isEmpty) return null;

    if (input.contains(':')) {
      final parts = input.split(':');
      if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
        return null;
      }
      return int.tryParse(parts.last);
    }

    if (input.length < 3) return null;
    final rawMinute = input.substring(input.length - 2);
    return int.tryParse(rawMinute);
  }

  bool _isCorrectInput() {
    final hour = _parseHourFromInput();
    final minute = _parseMinuteFromInput();
    if (hour == null || minute == null) return false;
    if (minute < 0 || minute > 59) return false;

    final normalizedHour = hour == 0 ? 12 : ((hour - 1) % 12) + 1;
    return normalizedHour == targetHour && minute == targetMinute;
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();

    setState(() {
      if (value == '-') return;

      if (value == ':') {
        if (input.isEmpty || input.contains(':')) return;
        input += ':';
        return;
      }

      if (input.contains(':')) {
        final parts = input.split(':');
        final minutePart = parts.length > 1 ? parts.last : '';
        if (minutePart.length >= 2) return;
        input += value;
        return;
      }

      if (input.length >= 4) return;
      input += value;
    });
  }

  void clearInput() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    setState(() => input = '');
  }

  void submitInput() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();

    final submittedAnswer = input.isEmpty ? 'No answer' : _displayInput();
    if (_isCorrectInput()) {
      SoundService().playCorrectSound();
      final leveledUp = _handleCorrectAnswer();
      setState(() {
        showCorrectSplash = true;
        isGameOver = true;
      });

      Future.delayed(_correctFeedbackDuration, () {
        if (!mounted) return;
        setState(() {
          showCorrectSplash = false;
        });

        if (leveledUp) {
          showLevelUpPage();
        } else {
          setState(() {
            isGameOver = false;
          });
          _generateClockTime();
        }
      });
      return;
    }

    SoundService().playIncorrectSplashSound();
    setState(() {
      showIncorrectSplash = true;
      hearts--;
      streak = 0;
      isGameOver = true;
    });

    unawaited(saveScore().catchError((error) {
      debugPrint('Error saving Analog Clock score: $error');
    }));

    Future.delayed(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() {
        showIncorrectSplash = false;
      });
      showGameOverScreen(submittedAnswer);
    });
  }

  bool _handleCorrectAnswer() {
    streak++;
    score += 10 + (level * 2);
    return _updateLevel();
  }

  void _handleTimeout() {
    if (isGameOver) return;
    setState(() {
      isGameOver = true;
      hearts--;
      streak = 0;
      showIncorrectSplash = true;
    });
    SoundService().playIncorrectSplashSound();
    unawaited(saveScore().catchError((error) {
      debugPrint('Error saving Analog Clock timeout score: $error');
    }));

    Future.delayed(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() {
        showIncorrectSplash = false;
      });
      showGameOverScreen('Timeout');
    });
  }

  void showLevelUpPage() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpPopup(
        newLevel: level,
        message: 'Clock questions are getting harder. Keep going!',
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            isGameOver = false;
          });
          _generateClockTime();
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
        correctAnswer: _correctAnswerLabel,
        heartsRemaining: hearts,
        score: score,
        level: level,
        onRetry: () {
          Navigator.pop(context);
          if (hearts <= 0) {
            startGame();
          } else {
            setState(() {
              input = '';
              isGameOver = false;
              timerKey = UniqueKey();
            });
            _generateClockTime();
          }
        },
        onBack: () {
          Navigator.pop(context);
          setState(() {
            hasStarted = false;
            isGameOver = false;
            showCorrectSplash = false;
            showIncorrectSplash = false;
            score = 0;
            level = 1;
            previousLevel = 1;
            hearts = 3;
            streak = 0;
            input = '';
          });
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

      await GameLogger.logGame(gameName: _gameName, score: score);

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userRef.get();
      final currentHighScore = snapshot.data()?['analog_clock_highscore'] ?? 0;
      if (score > currentHighScore) {
        await userRef.set({
          'analog_clock_highscore': score,
          'analog_clock_level': level,
          'analog_clock_last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          'analog_clock_last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await updateLeaderboardEntry(gameName: _gameName, newScore: score);
    } catch (error) {
      debugPrint('Error saving Analog Clock score: $error');
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _inkColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-34, -18),
          drift: Offset(14, 12),
          size: 150,
          color: Color(0x334CAF50),
          borderColor: Color(0x4D2F5233),
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topRight,
          baseOffset: Offset(28, 74),
          drift: Offset(12, 14),
          size: 112,
          color: Color(0x33FF9800),
          borderColor: Color(0x4D2F5233),
          symbol: '⏰',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 26,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.roundedSquare,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(30, 36),
          drift: Offset(11, 13),
          size: 118,
          color: Color(0x2E4CAF50),
          borderColor: Color(0x4D2F5233),
          cornerRadius: 28,
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

  Widget _buildInlineAnswerBox() {
    final displayText = _displayInput();
    final isPlaceholder = input.isEmpty;

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 210,
          maxWidth: 340,
          minHeight: 54,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlaceholder
                ? const Color(0xFFD6DFEB)
                : _accentColor.withValues(alpha: 0.75),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: isPlaceholder ? 20 : 30,
              fontWeight: FontWeight.w900,
              color: isPlaceholder ? const Color(0xFF6B7280) : _inkColor,
              letterSpacing: isPlaceholder ? 0 : 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(color: _inkColor, width: 2),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 56,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Analog Clock Challenge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Look at the analog clock, then type the time using the numpad. Example: 7:30.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: startGame,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockPanel(BoxConstraints constraints) {
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width;
    final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : screen.height;
    final clockSize = min(maxWidth * 0.88, maxHeight * 0.58).clamp(190.0, 380.0);

    return Center(
      child: SizedBox(
        width: clockSize,
        height: clockSize,
        child: CustomPaint(
          painter: _AnalogClockPainter(
            hour: targetHour,
            minute: targetMinute,
            inkColor: _inkColor,
            accentColor: _accentColor,
          ),
        ),
      ),
    );
  }

  double _keypadPanelSize(BoxConstraints constraints) {
    final screen = MediaQuery.sizeOf(context);
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : screen.height * 0.42;
    return min(width * 0.94, height * 0.98).clamp(230.0, 520.0);
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
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
        ),
        const SizedBox(height: 12),
        HeartsDisplay(hearts: hearts),
        const SizedBox(height: 12),
        Expanded(
          flex: 5,
          child: _card(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'What time is shown on the clock?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _buildClockPanel(constraints)),
                    const SizedBox(height: 10),
                    _buildInlineAnswerBox(),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelSize = _keypadPanelSize(constraints);
              final buttonSize = ((panelSize - 36) / 4).clamp(48.0, 132.0);
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: panelSize,
                  height: panelSize,
                  child: NumberPad(
                    input: input,
                    isDisabled: isGameOver,
                    onNumberTap: appendInput,
                    onClear: clearInput,
                    onSubmit: submitInput,
                    panelSize: panelSize,
                    buttonSize: buttonSize,
                    alignment: Alignment.center,
                    showInputDisplay: false,
                    showColonButton: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Analog Clock'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _onBackPressed,
            ),
          ),
          body: _buildBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    if (!hasStarted) _buildStartScreen() else _buildGameUI(),
                    if (_showExitConfirmation)
                      Positioned.fill(
                        child: LeaveWarningOverlay(
                          title: 'Leave game?',
                          message: 'Your current progress in this game will be lost.',
                          onOk: _confirmExitFromBack,
                          onBack: _cancelExitConfirmation,
                          okText: 'Leave',
                          backText: 'Stay',
                        ),
                      ),
                    if (showCorrectSplash)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CorrectSplash(
                            duration: _correctFeedbackDuration,
                          ),
                        ),
                      ),
                    if (showIncorrectSplash)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: IncorrectSplash(
                            duration: _incorrectFeedbackDuration,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final Color inkColor;
  final Color accentColor;

  const _AnalogClockPainter({
    required this.hour,
    required this.minute,
    required this.inkColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final shadowPaint = Paint()
      ..color = const Color(0x332C3550)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(5, 6), radius * 0.92, shadowPaint);

    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.92, facePaint);

    final borderPaint = Paint()
      ..color = inkColor
      ..strokeWidth = radius * 0.045
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.92, borderPaint);

    final tickPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.75)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final isHourTick = i % 5 == 0;
      final angle = (i * 6 - 90) * pi / 180;
      final outer = Offset(
        center.dx + cos(angle) * radius * 0.82,
        center.dy + sin(angle) * radius * 0.82,
      );
      final inner = Offset(
        center.dx + cos(angle) * radius * (isHourTick ? 0.70 : 0.76),
        center.dy + sin(angle) * radius * (isHourTick ? 0.70 : 0.76),
      );
      tickPaint.strokeWidth = isHourTick ? radius * 0.025 : radius * 0.011;
      canvas.drawLine(inner, outer, tickPaint);
    }

    for (int number = 1; number <= 12; number++) {
      final angle = (number * 30 - 90) * pi / 180;
      final offset = Offset(
        center.dx + cos(angle) * radius * 0.58,
        center.dy + sin(angle) * radius * 0.58,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: inkColor,
            fontSize: radius * 0.145,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final minuteAngle = (minute * 6 - 90) * pi / 180;
    final hourAngle = (((hour % 12) + minute / 60) * 30 - 90) * pi / 180;

    final hourPaint = Paint()
      ..color = inkColor
      ..strokeWidth = radius * 0.065
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + cos(hourAngle) * radius * 0.42,
        center.dy + sin(hourAngle) * radius * 0.42,
      ),
      hourPaint,
    );

    final minutePaint = Paint()
      ..color = accentColor
      ..strokeWidth = radius * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + cos(minuteAngle) * radius * 0.64,
        center.dy + sin(minuteAngle) * radius * 0.64,
      ),
      minutePaint,
    );

    final centerPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.055, centerPaint);

    final centerBorderPaint = Paint()
      ..color = inkColor
      ..strokeWidth = radius * 0.012
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.055, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.inkColor != inkColor ||
        oldDelegate.accentColor != accentColor;
  }
}
