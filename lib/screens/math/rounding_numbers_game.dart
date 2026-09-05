import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/player_proctoring_preference.dart';
import '../../services/game_result_recorder.dart';
import '../../services/game_logger.dart';
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
import '../../widgets/number_pad.dart';

enum _RoundingQuestionType {
  nearestHundredTo1000,
  nearestHundredTo10000,
  nearestThousandTo10000,
  mixedTensHundreds,
  mixedTensHundredsThousands,
}

class RoundingNumbersGame extends StatefulWidget {
  const RoundingNumbersGame({super.key});

  @override
  State<RoundingNumbersGame> createState() => _RoundingNumbersGameState();
}

class _RoundingNumbersGameState extends State<RoundingNumbersGame> {
  static const String _gameName = 'Rounding Numbers';
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1450);

  final Random _random = Random();
  final FaceProctorService _faceProctor = createFaceProctorService();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;

  /// Set the moment the player commits to leaving, and never cleared.
  ///
  /// Every exit path below `await`s a save before it pops, and
  /// `saveBeforeLeaving` deliberately waits up to three seconds. The Leave
  /// button stayed live for that whole window, so each extra tap queued
  /// another `Navigator.pop` - a few quick taps emptied the navigator and left
  /// a black screen.
  bool _isLeavingScreen = false;
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
  /// `generateQuestion()`, which clears `isGameOver` and mints a fresh
  /// `timerKey` - so a face violation or an app-background landing inside that
  /// window put the "Leave / Stay" overlay on screen with a live timer
  /// counting down underneath it, and the player lost a heart to a question
  /// they could not see. Cancelled when the overlay locks, and on dispose.
  Timer? _feedbackTimer;

  int score = 0;
  int _levelPoints = 0;
  int level = 1;
  int hearts = 3;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  int timeLimit = 13;
  int numberToRound = 689;
  int roundTo = 100;
  int correctAnswer = 700;
  String input = '';
  String instruction = 'Round to the nearest hundred.';
  String expression = '689 rounds to ___';
  _RoundingQuestionType questionType = _RoundingQuestionType.nearestHundredTo1000;
  Key timerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    GameLogger.endSession(_gameName);
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
      score = 0;
      _levelPoints = 0;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      input = '';
      timeLimit = 13;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  List<_RoundingQuestionType> _availableTypes() {
    if (level <= 1) return [_RoundingQuestionType.nearestHundredTo1000];
    if (level == 2) {
      return [
        _RoundingQuestionType.nearestHundredTo1000,
        _RoundingQuestionType.nearestHundredTo10000,
      ];
    }
    if (level == 3) {
      return [
        _RoundingQuestionType.nearestHundredTo1000,
        _RoundingQuestionType.nearestHundredTo10000,
        _RoundingQuestionType.nearestThousandTo10000,
      ];
    }
    if (level <= 5) {
      return [
        _RoundingQuestionType.nearestHundredTo10000,
        _RoundingQuestionType.nearestThousandTo10000,
        _RoundingQuestionType.mixedTensHundreds,
      ];
    }
    return _RoundingQuestionType.values;
  }

  void generateQuestion() {
    final types = _availableTypes();
    final nextType = types[_random.nextInt(types.length)];

    late final int maxValue;
    late final int step;
    late final String nextInstruction;

    switch (nextType) {
      case _RoundingQuestionType.nearestHundredTo1000:
        maxValue = 1000;
        step = 100;
        nextInstruction = 'Round to the nearest hundred, within 0–1,000.';
        break;
      case _RoundingQuestionType.nearestHundredTo10000:
        maxValue = 10000;
        step = 100;
        nextInstruction = 'Round to the nearest hundred, within 0–10,000.';
        break;
      case _RoundingQuestionType.nearestThousandTo10000:
        maxValue = 10000;
        step = 1000;
        nextInstruction = 'Round to the nearest thousand, within 0–10,000.';
        break;
      case _RoundingQuestionType.mixedTensHundreds:
        maxValue = 10000;
        step = _random.nextBool() ? 10 : 100;
        nextInstruction = 'Mixed rounding: round to the nearest ${_placeLabel(step)}.';
        break;
      case _RoundingQuestionType.mixedTensHundredsThousands:
        maxValue = 10000;
        step = [10, 100, 1000][_random.nextInt(3)];
        nextInstruction = 'Mixed rounding: round to the nearest ${_placeLabel(step)}.';
        break;
    }

    var nextNumber = _random.nextInt(maxValue + 1);
    // Avoid questions that feel too empty for the early rounds.
    if (level <= 2 && nextNumber < 100) {
      nextNumber += 100;
    }

    final nextAnswer = _roundToNearest(nextNumber, step);

    setState(() {
      questionType = nextType;
      numberToRound = nextNumber;
      roundTo = step;
      correctAnswer = nextAnswer;
      instruction = nextInstruction;
      expression = '${_formatNumber(nextNumber)} rounds to ___';
      input = '';
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });
  }

  int _roundToNearest(int value, int step) {
    return ((value + (step ~/ 2)) ~/ step) * step;
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 14;
    if (level <= 4) return 12;
    if (level <= 7) return 10;
    return 9;
  }

  String _placeLabel(int step) {
    switch (step) {
      case 10:
        return 'ten';
      case 100:
        return 'hundred';
      case 1000:
        return 'thousand';
      default:
        return step.toString();
    }
  }

  String _modeLabel() {
    switch (questionType) {
      case _RoundingQuestionType.nearestHundredTo1000:
        return 'Hundreds 0–1K';
      case _RoundingQuestionType.nearestHundredTo10000:
        return 'Hundreds 0–10K';
      case _RoundingQuestionType.nearestThousandTo10000:
        return 'Thousands';
      case _RoundingQuestionType.mixedTensHundreds:
        return 'Mixed 10s/100s';
      case _RoundingQuestionType.mixedTensHundredsThousands:
        return 'Mixed All';
    }
  }

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final indexFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    if (value == '-') return;
    if (input.length >= 5) return;
    if (input == '0' && value == '0') return;

    setState(() {
      if (input == '0' && value != '0') {
        input = value;
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

  /// Deletes the last character, for the backspace key.
  void backspaceInput() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    setState(() {
      if (input.isNotEmpty) {
        input = input.substring(0, input.length - 1);
      }
    });
  }

  void submitInput() {
    if (isGameOver || input.isEmpty) return;
    SoundService().playButtonSoundNow();

    final userAnswer = int.tryParse(input);
    if (userAnswer == correctAnswer) {
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

    _handleIncorrect(input.isEmpty ? 'No answer' : _formatNumber(userAnswer ?? 0));
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
      debugPrint('Error saving Rounding Numbers score: $error');
    }));

    _feedbackTimer = Timer(_incorrectFeedbackDuration, () {
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
            'Great rounding!\nYou will now see faster mixed rounding questions.',
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
        correctAnswer: _formatNumber(correctAnswer),
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
      // Leaving was abandoned; the Leave button must work again.
      _isLeavingScreen = false;
      _showExitConfirmation = false;
      isGameOver = false;
      timerKey = UniqueKey();
    });
  }

  Future<void> _confirmExitFromBack() async {
    if (_isLeavingScreen) return;
    setState(() => _isLeavingScreen = true);
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
    // Guarded as a backstop: popping the last route is what turns the screen
    // black, and the flag above should already have made this unreachable.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Nothing to pop, so this screen is the root route. Release the claim
    // rather than leaving it permanently unleavable.
    if (mounted) setState(() => _isLeavingScreen = false);
  }

  Future<void> saveScore() async {
    await _saveGate.run(() async {
      await saveGameResult(
        gameName: _gameName,
        score: score,
        level: level,
        difficulty: gameDifficultyModeLabel(_selectedMode),
        proctored: _runProctored,
        storageKey: 'rounding_numbers',
      );
    });
  }

  Future<void> _onBackPressed() async {
    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    // Claimed only once leaving is genuinely under way. Setting it before
    // the branch above put the confirmation dialog on screen with
    // `isBusy: true`, which disables *both* its buttons - and this handler
    // then returned at the guard, so the arrow and the Android gesture were
    // dead too. The only way out was to force-quit the app.
    if (_isLeavingScreen) return;
    setState(() => _isLeavingScreen = true);

    SoundService().playButtonSoundNow();
    if (hasStarted && score > 0) {
      // Bounded: offline this never returned, so the back arrow did nothing.
      await saveBeforeLeaving(saveScore);
    }
    if (!mounted) return;
    // Guarded as a backstop: popping the last route is what turns the screen
    // black, and the flag above should already have made this unreachable.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Nothing to pop, so this screen is the root route. Release the claim
    // rather than leaving it permanently unleavable.
    if (mounted) setState(() => _isLeavingScreen = false);
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
            title: const Text('Rounding Numbers'),
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
                      enableFaceProctor: faceProctorEnabledFor(isExam: false),
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
                    message: 'Your current progress in this game will be lost.',
                    onOk: _confirmExitFromBack,
                    onBack: _cancelExitConfirmation,
                    isBusy: _isLeavingScreen,
                    busyText: 'Leaving...',
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
      duration: const Duration(seconds: 20),
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-34, -22),
          drift: Offset(16, 11),
          size: 124,
          color: Color(0x304CAF50),
          borderColor: Color(0x4A2F5233),
          initialRotation: -0.12,
          symbol: '700',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 28,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topRight,
          baseOffset: Offset(30, 80),
          drift: Offset(12, 15),
          size: 112,
          color: Color(0x30FF9800),
          borderColor: Color(0x4A2F5233),
          initialRotation: 0.22,
          symbol: '~',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 30,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(32, 34),
          drift: Offset(13, 14),
          size: 122,
          color: Color(0x2A4CAF50),
          borderColor: Color(0x402F5233),
          symbol: '100',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 26,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(20, 26),
          drift: Offset(11, 12),
          size: 100,
          color: Color(0x28FF9800),
          borderColor: Color(0x402F5233),
          symbol: '10',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 24,
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

  Widget _buildStartPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsivePanelMaxWidth(
            MediaQuery.sizeOf(context).width,
          ),
        ),
        child: _card(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0x264CAF50),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _inkColor, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '~100',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _inkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Rounding Numbers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Round numbers to the nearest tens, hundreds, and thousands.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Difficulty',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _inkColor),
              ),
              const SizedBox(height: 6),
              DifficultyModeSelector(
                selected: _selectedMode,
                accentColor: _accentColor,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 4),
              Text(
                gameDifficultyModeDescription(_selectedMode),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _inkColor),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SoundService().playButtonSoundNow();
                    startGame();
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Rounding'),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statPill('Score', '$score', Icons.stars_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _statPill('Level', '$level', Icons.trending_up_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _statPill('Mode', _modeLabel(), Icons.rounded_corner_rounded)),
          ],
        ),
        if (gameDifficultyModeHasTimer(_selectedMode)) ...[
          const SizedBox(height: 12),
          _card(
            padding: const EdgeInsets.all(14),
            child: GameTimer(
              key: timerKey,
              seconds: timeLimit,
              isPaused: () => isGameOver,
              onTimeUp: _handleTimeout,
              showBar: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        HeartsDisplay(
          hearts: hearts,
          maxHearts: gameDifficultyModeHearts(_selectedMode),
        ),
        const SizedBox(height: 12),
        _card(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  expression,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: _inkColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _answerBox(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildCenteredNumberPad()),
      ],
    );
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEFFAFFF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _inkColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242C3550),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _inkColor,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _inkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerBox() {
    final parsedInput = int.tryParse(input);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 58),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6DFEB), width: 2),
      ),
      child: Text(
        input.isEmpty ? 'Your Answer' : _formatNumber(parsedInput ?? 0),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: input.isEmpty ? 22 : 30,
          fontWeight: FontWeight.w900,
          color: input.isEmpty ? const Color(0xFF6F7A6D) : _inkColor,
        ),
      ),
    );
  }

  Widget _buildCenteredNumberPad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height * 0.46;
        final panelSize = min(availableWidth * 0.94, availableHeight * 0.98)
            .clamp(270.0, 560.0)
            .toDouble();
        final buttonSize = ((panelSize - 92) / 4).clamp(48.0, 118.0).toDouble();

        return Center(
          child: SizedBox(
            width: panelSize,
            height: panelSize,
            child: NumberPad(
              input: input,
              isDisabled: isGameOver,
              onNumberTap: appendInput,
              onClear: clearInput,
                    onBackspace: backspaceInput,
              onSubmit: submitInput,
              panelSize: panelSize,
              buttonSize: buttonSize,
              alignment: Alignment.center,
              showInputDisplay: false,
            ),
          ),
        );
      },
    );
  }
}
