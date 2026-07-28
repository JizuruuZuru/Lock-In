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

enum _PlaceValueQuestionType {
  build3,
  missing3,
  build4,
  missing4,
}

class PlaceValueGame extends StatefulWidget {
  const PlaceValueGame({super.key});

  @override
  State<PlaceValueGame> createState() => _PlaceValueGameState();
}

class _PlaceValueGameState extends State<PlaceValueGame> {
  static const String _gameName = 'Place Value';
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
  int timeLimit = 14;
  int correctAnswer = 0;
  int correctWholeNumber = 0;
  String input = '';
  String expression = '200 + 70 + 1 = ___';
  String instruction = 'Build the number from the parts.';
  _PlaceValueQuestionType questionType = _PlaceValueQuestionType.build3;
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
      timeLimit = 14;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  List<_PlaceValueQuestionType> _availableTypes() {
    if (level <= 1) return [_PlaceValueQuestionType.build3];
    if (level == 2) {
      return [
        _PlaceValueQuestionType.build3,
        _PlaceValueQuestionType.missing3,
      ];
    }
    if (level == 3) {
      return [
        _PlaceValueQuestionType.build3,
        _PlaceValueQuestionType.missing3,
        _PlaceValueQuestionType.build4,
      ];
    }
    return _PlaceValueQuestionType.values;
  }

  int _digit({bool allowZero = false}) {
    if (allowZero) return _random.nextInt(10);
    return _random.nextInt(9) + 1;
  }

  void generateQuestion() {
    final types = _availableTypes();
    final nextType = types[_random.nextInt(types.length)];
    final h = _digit();
    final t = _digit();
    final o = _digit();
    final th = _digit();

    late final int answer;
    late final int wholeNumber;
    late final String nextExpression;
    late final String nextInstruction;

    switch (nextType) {
      case _PlaceValueQuestionType.build3:
        wholeNumber = (h * 100) + (t * 10) + o;
        answer = wholeNumber;
        nextExpression = '${h * 100} + ${t * 10} + $o = ___';
        nextInstruction = 'Build a 3-digit number from the parts.';
        break;
      case _PlaceValueQuestionType.missing3:
        wholeNumber = (h * 100) + (t * 10) + o;
        final parts = [h * 100, t * 10, o];
        final hiddenIndex = _random.nextInt(parts.length);
        answer = parts[hiddenIndex];
        final shownParts = [
          for (var i = 0; i < parts.length; i++)
            i == hiddenIndex ? '___' : _formatNumber(parts[i]),
        ];
        nextExpression = '${shownParts.join(' + ')} = ${_formatNumber(wholeNumber)}';
        nextInstruction = 'Find the missing place value.';
        break;
      case _PlaceValueQuestionType.build4:
        wholeNumber = (th * 1000) + (h * 100) + (t * 10) + o;
        answer = wholeNumber;
        nextExpression = '${_formatNumber(th * 1000)} + ${h * 100} + ${t * 10} + $o = ___';
        nextInstruction = 'Build a 4-digit number from the parts.';
        break;
      case _PlaceValueQuestionType.missing4:
        wholeNumber = (th * 1000) + (h * 100) + (t * 10) + o;
        final parts = [th * 1000, h * 100, t * 10, o];
        final hiddenIndex = _random.nextInt(parts.length);
        answer = parts[hiddenIndex];
        final shownParts = [
          for (var i = 0; i < parts.length; i++)
            i == hiddenIndex ? '___' : _formatNumber(parts[i]),
        ];
        nextExpression = '${shownParts.join(' + ')} = ${_formatNumber(wholeNumber)}';
        nextInstruction = 'Find the missing place value.';
        break;
    }

    setState(() {
      questionType = nextType;
      correctAnswer = answer;
      correctWholeNumber = wholeNumber;
      expression = nextExpression;
      instruction = nextInstruction;
      input = '';
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 15;
    if (level <= 4) return 13;
    if (level <= 7) return 11;
    return 10;
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

  String _questionTypeLabel() {
    switch (questionType) {
      case _PlaceValueQuestionType.build3:
        return 'Build 3-digit';
      case _PlaceValueQuestionType.missing3:
        return 'Missing 3-digit';
      case _PlaceValueQuestionType.build4:
        return 'Build 4-digit';
      case _PlaceValueQuestionType.missing4:
        return 'Missing 4-digit';
    }
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
      debugPrint('Error saving Place Value score: $error');
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
            'Great place value skills!\nMore 4-digit and missing-value questions are coming.',
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
      final previousHighscore = snapshot.data()?['place_value_highscore'];
      final currentHighscore = previousHighscore is num
          ? previousHighscore.toInt()
          : 0;

      await userRef.set({
        'place_value_last_score': score,
        'place_value_last_level': level,
        'place_value_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) 'place_value_highscore': score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(
          gameName: _gameName,
          newScore: score,
          difficulty: gameDifficultyModeLabel(_selectedMode),
        );
      }
    } catch (error) {
      debugPrint('Error in saveScore (Place Value): $error');
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
            title: const Text('Place Value'),
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
          baseOffset: Offset(-34, -22),
          drift: Offset(16, 11),
          size: 124,
          color: Color(0x304CAF50),
          borderColor: Color(0x4A2F5233),
          initialRotation: -0.12,
          symbol: '100',
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
          symbol: '+',
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
          symbol: '10',
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
          symbol: '1',
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
                    '271',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _inkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Place Value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Build 3-digit and 4-digit numbers, then find missing place values.',
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
                  label: const Text('Start Place Value'),
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
            Expanded(child: _statPill('Mode', _questionTypeLabel(), Icons.category_rounded)),
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
        input.isEmpty ? 'Your Answer' : _formatNumber(int.tryParse(input) ?? 0),
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
