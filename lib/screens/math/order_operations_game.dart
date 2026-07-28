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
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/game_security_overlay.dart';
import '../../widgets/level_up_popup.dart';
import '../../widgets/number_pad.dart';

enum _OrderQuestionType {
  addSubtractThree,
  addSubtractFour,
  addSubtractFive,
  addSubtractSix,
  mixedNoParentheses,
  mixedWithParentheses,
  mixedFiveNumbers,
  mixedSixNumbers,
}

class OrderOperationsGame extends StatefulWidget {
  const OrderOperationsGame({super.key});

  @override
  State<OrderOperationsGame> createState() => _OrderOperationsGameState();
}

class _OrderOperationsGameState extends State<OrderOperationsGame> {
  static const String _gameName = 'Order of Operations';
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
  bool _isSavingScore = false;

  int score = 0;
  int _levelPoints = 0;
  int level = 1;
  int hearts = 3;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  int timeLimit = 16;
  int correctAnswer = 7;
  String input = '';
  String instruction = 'Solve using order of operations.';
  String expression = '23 - (3 + 13) = ___';
  _OrderQuestionType questionType = _OrderQuestionType.addSubtractThree;
  Key timerKey = UniqueKey();

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
      _levelPoints = 0;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      input = '';
      timeLimit = 16;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  List<_OrderQuestionType> _availableTypes() {
    if (level <= 1) return [_OrderQuestionType.addSubtractThree];
    if (level == 2) return [_OrderQuestionType.addSubtractFour];
    if (level == 3) {
      return [
        _OrderQuestionType.addSubtractThree,
        _OrderQuestionType.addSubtractFour,
        _OrderQuestionType.addSubtractFive,
      ];
    }
    if (level == 4) {
      return [
        _OrderQuestionType.addSubtractFour,
        _OrderQuestionType.addSubtractFive,
        _OrderQuestionType.addSubtractSix,
      ];
    }
    if (level == 5) {
      return [
        _OrderQuestionType.addSubtractFive,
        _OrderQuestionType.addSubtractSix,
        _OrderQuestionType.mixedNoParentheses,
      ];
    }
    if (level == 6) {
      return [
        _OrderQuestionType.mixedNoParentheses,
        _OrderQuestionType.mixedWithParentheses,
      ];
    }
    if (level == 7) {
      return [
        _OrderQuestionType.mixedWithParentheses,
        _OrderQuestionType.mixedFiveNumbers,
      ];
    }
    return _OrderQuestionType.values;
  }

  int _rand(int min, int max) => min + _random.nextInt(max - min + 1);

  void generateQuestion() {
    final types = _availableTypes();
    final nextType = types[_random.nextInt(types.length)];

    late final String nextExpression;
    late final String nextInstruction;
    late final int nextAnswer;

    switch (nextType) {
      case _OrderQuestionType.addSubtractThree:
        final b = _rand(2, 14 + level);
        final c = _rand(2, 14 + level);
        final a = b + c + _rand(4, 35 + level);
        nextExpression = '$a - ($b + $c) = ___';
        nextAnswer = a - (b + c);
        nextInstruction = 'Add / subtract with parentheses — three numbers.';
        break;

      case _OrderQuestionType.addSubtractFour:
        final b = _rand(4, 18 + level);
        final c = _rand(3, 18 + level);
        final d = _rand(1, min(12 + level, b + c - 1));
        final inner = b + c - d;
        final a = inner + _rand(5, 42 + level);
        nextExpression = '$a - ($b + $c - $d) = ___';
        nextAnswer = a - inner;
        nextInstruction = 'Add / subtract with parentheses — four numbers.';
        break;

      case _OrderQuestionType.addSubtractFive:
        var a = _rand(10, 45);
        final b = _rand(4, 25);
        final c = _rand(3, 22);
        final d = _rand(5, 30);
        final e = _rand(3, 26);
        var answer = (a + b) + c - (d + e);
        if (answer < -20) {
          a += answer.abs() + _rand(2, 12);
          answer = (a + b) + c - (d + e);
        }
        nextExpression = '($a + $b) + $c - ($d + $e) = ___';
        nextAnswer = answer;
        nextInstruction = 'Add / subtract with parentheses — five numbers.';
        break;

      case _OrderQuestionType.addSubtractSix:
        final a = _rand(10, 45);
        final b = _rand(5, 25);
        final c = _rand(3, 24);
        final d = _rand(20, 55);
        final e = _rand(3, 18);
        final f = _rand(1, 16);
        nextExpression = '($a + $b) + $c - ($d - $e + $f) = ___';
        nextAnswer = (a + b) + c - (d - e + f);
        nextInstruction = 'Add / subtract with parentheses — six numbers.';
        break;

      case _OrderQuestionType.mixedNoParentheses:
        final a = _rand(3, 35);
        final b = _rand(2, 12);
        final c = _rand(2, 12);
        final d = _rand(3, 35);
        nextExpression = '$a + $b × $c - $d = ___';
        nextAnswer = a + (b * c) - d;
        nextInstruction = 'Add / subtract / multiply with no parentheses.';
        break;

      case _OrderQuestionType.mixedWithParentheses:
        final a = _rand(2, 24);
        final b = _rand(2, 9);
        final c = _rand(2, 15);
        final d = _rand(2, 15);
        nextExpression = '$a + $b × ($c + $d) = ___';
        nextAnswer = a + b * (c + d);
        nextInstruction = 'Add / subtract / multiply with parentheses.';
        break;

      case _OrderQuestionType.mixedFiveNumbers:
        final a = _rand(2, 20);
        final b = _rand(2, 12);
        final c = _rand(2, 10);
        final d = _rand(8, 35);
        final e = _rand(2, min(18, d - 1));
        nextExpression = '$a + $b × $c + ($d - $e) = ___';
        nextAnswer = a + (b * c) + (d - e);
        nextInstruction = 'Add / subtract / multiply with parentheses — five numbers.';
        break;

      case _OrderQuestionType.mixedSixNumbers:
        final a = _rand(2, 20);
        final b = _rand(2, 12);
        final c = _rand(2, 10);
        final d = _rand(12, 36);
        final e = _rand(2, min(18, d - 1));
        final f = _rand(2, 6);
        nextExpression = '$a + $b × $c + ($d - $e) × $f = ___';
        nextAnswer = a + (b * c) + ((d - e) * f);
        nextInstruction = 'Add / subtract / multiply with parentheses — six numbers.';
        break;
    }

    setState(() {
      questionType = nextType;
      expression = nextExpression;
      instruction = nextInstruction;
      correctAnswer = nextAnswer;
      input = '';
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 17;
    if (level <= 4) return 15;
    if (level <= 6) return 13;
    return 12;
  }

  String _modeLabel() {
    switch (questionType) {
      case _OrderQuestionType.addSubtractThree:
        return '3 Numbers';
      case _OrderQuestionType.addSubtractFour:
        return '4 Numbers';
      case _OrderQuestionType.addSubtractFive:
        return '5 Numbers';
      case _OrderQuestionType.addSubtractSix:
        return '6 Numbers';
      case _OrderQuestionType.mixedNoParentheses:
        return 'No Parentheses';
      case _OrderQuestionType.mixedWithParentheses:
        return 'Parentheses';
      case _OrderQuestionType.mixedFiveNumbers:
        return 'Mixed 5';
      case _OrderQuestionType.mixedSixNumbers:
        return 'Mixed 6';
    }
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();

    if (value == '-') {
      setState(() {
        if (input.startsWith('-')) {
          input = input.substring(1);
        } else {
          input = '-$input';
        }
      });
      return;
    }

    if (input.replaceAll('-', '').length >= 5) return;
    if (input == '0' && value == '0') return;

    setState(() {
      if (input == '0' && value != '0') {
        input = value;
      } else if (input == '-0' && value != '0') {
        input = '-$value';
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
    if (isGameOver || input.isEmpty || input == '-') return;
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
      debugPrint('Error saving Order of Operations score: $error');
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
            'Great solving!\nThe next level mixes more numbers, parentheses, and multiplication.',
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
        correctAnswer: correctAnswer.toString(),
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

      await GameLogger.logGame(
        gameName: _gameName,
        score: score,
        difficulty: gameDifficultyModeLabel(_selectedMode),
      );

      final snapshot = await userRef.get();
      final previousHighscore = snapshot.data()?['order_operations_highscore'];
      final currentHighscore = previousHighscore is num
          ? previousHighscore.toInt()
          : 0;

      await userRef.set({
        'order_operations_last_score': score,
        'order_operations_last_level': level,
        'order_operations_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) 'order_operations_highscore': score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(
          gameName: _gameName,
          newScore: score,
          difficulty: gameDifficultyModeLabel(_selectedMode),
        );
      }
    } catch (error) {
      debugPrint('Error in saveScore (Order of Operations): $error');
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
            title: const Text('Order of Operations'),
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
                      gameName: _gameName,
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
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      gradientColors: const [_bgTopColor, _bgBottomColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
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
          symbol: '( )',
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
          symbol: '×',
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
          symbol: '+ -',
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
          symbol: '=',
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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0x264CAF50),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _inkColor, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '( )',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: _inkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order of Operations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Solve expressions with parentheses, addition, subtraction, and multiplication.',
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
                  label: const Text('Start Solving'),
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
            Expanded(child: _statPill('Mode', _modeLabel(), Icons.functions_rounded)),
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
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
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
        final buttonSize = ((panelSize - 100) / 4).clamp(48.0, 114.0).toDouble();

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
              showSignToggle: true,
            ),
          ),
        );
      },
    );
  }
}
