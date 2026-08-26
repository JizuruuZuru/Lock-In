import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/game_logger.dart';
import '../../services/face_proctor_contract.dart';
import '../../services/face_proctor_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/leave_attempt_logger.dart';
import '../../services/sound_service.dart';
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
import '../../widgets/level_up_popup.dart';
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/game_security_overlay.dart';
import '../../widgets/number_pad.dart';

class RomanNumeralsGame extends StatefulWidget {
  const RomanNumeralsGame({super.key});

  @override
  State<RomanNumeralsGame> createState() => _RomanNumeralsGameState();
}

class _RomanNumeralsGameState extends State<RomanNumeralsGame> {
  static const Color _inkColor = Color(0xFF2C1B47);
  static const Color _bgTopColor = Color(0xFFFFF4E6);
  static const Color _bgBottomColor = Color(0xFFFFE0D6);
  static const Color _panelColor = Color(0xFFFFFBEE);
  static const Color _accentColor = Color(0xFF9C27B0);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1450);

  final Random _random = Random();
  final FaceProctorService _faceProctor = createFaceProctorService();

  int score = 0;
  int _levelPoints = 0;
  int level = 1;
  int hearts = 3;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  int timeLimit = 14;
  int correctAnswer = 1;
  String romanQuestion = 'I';
  String input = '';

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _isSavingScore = false;
  bool _showExitConfirmation = false;
  Key timerKey = UniqueKey();

  int get _maxNumber {
    if (level <= 1) return 20;
    if (level == 2) return 50;
    if (level == 3) return 100;
    if (level == 4) return 250;
    if (level == 5) return 500;
    if (level == 6) return 1000;
    return 3999;
  }

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
    GameLogger.startNewSession('Roman Numerals');
    setState(() {
      hasStarted = true;
      score = 0;
      _levelPoints = 0;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      timeLimit = 14;
      input = '';
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  void generateQuestion() {
    final maxNumber = _maxNumber;
    final nextNumber = _random.nextInt(maxNumber) + 1;
    setState(() {
      correctAnswer = nextNumber;
      romanQuestion = _toRoman(nextNumber);
      input = '';
      timerKey = UniqueKey();
    });
  }

  String _toRoman(int value) {
    const values = [
      1000,
      900,
      500,
      400,
      100,
      90,
      50,
      40,
      10,
      9,
      5,
      4,
      1,
    ];
    const numerals = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I',
    ];

    var remaining = value;
    final buffer = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      while (remaining >= values[i]) {
        buffer.write(numerals[i]);
        remaining -= values[i];
      }
    }
    return buffer.toString();
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();

    if (value == '-') return;
    if (input.length >= 4) return;
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

  void submitInput() {
    if (isGameOver || input.isEmpty) return;

    final userAnswer = int.tryParse(input);
    if (userAnswer == correctAnswer) {
      SoundService().playCorrectSound();
      final nextLevelPoints = _levelPoints + 10 + ((level - 1) * 2);
      final nextLevel = (nextLevelPoints ~/ 50) + 1;
      final didLevelUp = nextLevel > level;

      setState(() {
        showCorrectSplash = true;
        isGameOver = true;
        score += 1;
        _levelPoints = nextLevelPoints;
        if (didLevelUp) {
          level = nextLevel;
          timeLimit = max(6, 14 - (level - 1));
        }
      });

      Future.delayed(_correctFeedbackDuration, () {
        if (!mounted) return;
        setState(() {
          showCorrectSplash = false;
        });

        if (didLevelUp) {
          showLevelUpPage();
        } else {
          setState(() {
            isGameOver = false;
          });
          generateQuestion();
        }
      });
      return;
    }

    _handleIncorrect(input.isEmpty ? 'No answer' : input);
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
      debugPrint('Error saving Roman Numerals score: $error');
    }));

    Future.delayed(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() {
        showIncorrectSplash = false;
      });
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
            'Roman numerals are getting harder.\nNow converting up to $_maxNumber!',
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
        correctAnswer: '$correctAnswer  =  $romanQuestion',
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
          if (mounted) {
            Navigator.pop(context);
          }
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
        gameName: 'Roman Numerals',
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

      const gameName = 'Roman Numerals';
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);

      await GameLogger.logGame(
        gameName: gameName,
        score: score,
        difficulty: gameDifficultyModeLabel(_selectedMode),
        extraHighscoreFields: {'roman_numerals_highscore': score},
      );

      await userRef.set({
        'roman_numerals_last_score': score,
        'roman_numerals_last_level': level,
        'roman_numerals_last_played': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(
          gameName: gameName,
          newScore: score,
          difficulty: gameDifficultyModeLabel(_selectedMode),
        );
      }
    } catch (error) {
      debugPrint('Error in saveScore (Roman Numerals): $error');
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
            title: const Text('Roman Numerals'),
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
                      faceProctor: _faceProctor,
                      gameName: 'Roman Numerals',
                      isActive: hasStarted && !isGameOver && !showCorrectSplash && !showIncorrectSplash && !_showExitConfirmation,
                      onLockChanged: (locked) {
                        if (!mounted) return;
                        setState(() {
                          isGameOver = locked;
                          if (locked) {
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
                          await saveScore();
                        }
                        if (!mounted) return;
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
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
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
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      duration: const Duration(seconds: 20),
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-30, -24),
          drift: Offset(16, 11),
          size: 118,
          color: Color(0x2E9C27B0),
          borderColor: Color(0x4A2C1B47),
          initialRotation: -0.15,
          symbol: 'X',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 28,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topRight,
          baseOffset: Offset(30, 78),
          drift: Offset(12, 15),
          size: 106,
          color: Color(0x30F57C00),
          borderColor: Color(0x4A2C1B47),
          initialRotation: 0.22,
          symbol: 'V',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 30,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(30, 36),
          drift: Offset(13, 14),
          size: 122,
          color: Color(0x2A9C27B0),
          borderColor: Color(0x402C1B47),
          symbol: 'L',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 26,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(20, 26),
          drift: Offset(11, 12),
          size: 98,
          color: Color(0x28F57C00),
          borderColor: Color(0x402C1B47),
          symbol: 'M',
          contentColor: Color(0xFF2C1B47),
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
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0x269C27B0),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _inkColor, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'XIV',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: _inkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Roman Numerals',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Convert Roman numerals into numbers before the timer runs out.',
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
                  label: const Text('Start Roman Quest'),
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
            Expanded(child: _statPill('Max', '$_maxNumber', Icons.flag_rounded)),
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
        HeartsDisplay(hearts: hearts),
        const SizedBox(height: 12),
        _card(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              const Text(
                'What number is this?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  romanQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
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
        Expanded(
          child: _buildCenteredNumberPad(),
        ),
      ],
    );
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFBEE),
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
                    fontSize: 18,
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
        input.isEmpty ? 'Your Answer' : input,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: input.isEmpty ? 22 : 30,
          fontWeight: FontWeight.w900,
          color: input.isEmpty ? const Color(0xFF7A6D80) : _inkColor,
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
