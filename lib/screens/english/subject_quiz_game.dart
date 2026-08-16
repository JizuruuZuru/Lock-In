import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../../services/connectivity_service.dart';
import '../../services/face_proctor_service.dart';
import '../../services/game_logger.dart';
import '../../services/offline_subject_question_bank.dart';
import '../../services/subject_lesson_bank.dart';
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
import '../../widgets/game_security_overlay.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/hearts_display.dart';
import '../../widgets/incorrect_splash.dart';
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/level_up_popup.dart';
import '../../widgets/tappable_word_text.dart';
import '../../widgets/word_lookup_sheet.dart';

class SubjectQuizGame extends StatefulWidget {
  final SubjectQuizType subject;
  final String? lessonTitle;
  final String? lessonDescription;
  final String? lessonTopicsSummary;
  final Set<String>? allowedTopics;

  const SubjectQuizGame({
    super.key,
    required this.subject,
    this.lessonTitle,
    this.lessonDescription,
    this.lessonTopicsSummary,
    this.allowedTopics,
  });

  @override
  State<SubjectQuizGame> createState() => _SubjectQuizGameState();
}

class _SubjectQuizGameState extends State<SubjectQuizGame> {
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration =
      Duration(milliseconds: 1450);

  final Random _random = Random();
  final _faceProctor = createFaceProctorService();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;
  bool _isSavingScore = false;
  bool _isOffline = false;

  int score = 0;
  int _levelPoints = 0;
  int level = 1;
  int hearts = 3;
  int timeLimit = 22;
  String selectedAnswer = '';
  Key timerKey = UniqueKey();
  late SubjectQuizQuestion question;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  // Tracks which questions this session has already served, so the same
  // question doesn't repeat until every eligible one has been asked.
  final Set<String> _askedQuestionKeys = {};

  SubjectQuizConfig get _config =>
      SubjectQuestionBank.configFor(widget.subject);
  String get _quizTitle => widget.lessonTitle ?? '${_config.title} Quiz';
  String get _gameName => widget.lessonTitle == null
      ? '${_config.title} Quiz'
      : '${_config.title}: ${widget.lessonTitle}';

  String _safeScoreKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
    _refreshOfflineState();
  }

  @override
  void dispose() {
    GameLogger.endSession();
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
      _isSavingScore = false;
      score = 0;
      _levelPoints = 0;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      selectedAnswer = '';
      timerKey = UniqueKey();
      _askedQuestionKeys.clear();
    });
    generateQuestion();
  }

  int _timeLimitForLevel() {
    return (24 - min(level, 8)).clamp(15, 23).toInt();
  }

  void generateQuestion() {
    if (widget.allowedTopics != null && widget.allowedTopics!.isNotEmpty) {
      final nextQuestion = SubjectQuestionBank.randomQuestion(
        subject: widget.subject,
        level: level,
        random: _random,
        topics: widget.allowedTopics,
        excludeKeys: _askedQuestionKeys,
      );
      _askedQuestionKeys.add(SubjectQuestionBank.questionKey(nextQuestion));

      setState(() {
        question = nextQuestion;
        selectedAnswer = '';
        isGameOver = false;
        timerKey = UniqueKey();
        timeLimit = _timeLimitForLevel();
      });
      return;
    }

    final offlineSubject = widget.subject == SubjectQuizType.science
        ? OfflineSubject.science
        : OfflineSubject.english;
    final offlineQuestions = OfflineSubjectQuestionBank.questionsFor(
      offlineSubject,
      count: 32,
      topics: widget.allowedTopics,
    );

    final offlineQuestion = offlineQuestions.isEmpty
        ? null
        : offlineQuestions[_random.nextInt(offlineQuestions.length)];

    final nextQuestion = offlineQuestion == null
        ? _buildFallbackQuestion()
        : SubjectQuizQuestion(
            topic: offlineQuestion.topic,
            instruction: offlineQuestion.topic,
            prompt: offlineQuestion.prompt,
            correctAnswer: offlineQuestion.answer,
            choices: offlineQuestion.choices,
          );

    setState(() {
      question = nextQuestion;
      selectedAnswer = '';
      isGameOver = false;
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });
  }

  SubjectQuizQuestion _buildFallbackQuestion() {
    final lessonSubject = widget.subject == SubjectQuizType.science
        ? SubjectLessonSubject.science
        : SubjectLessonSubject.english;
    final lessonQuestion = SubjectLessonBank.randomQuestion(
      subject: lessonSubject,
      random: _random,
      topics: widget.allowedTopics,
    );

    return SubjectQuizQuestion(
      topic: lessonQuestion.topic,
      instruction: lessonQuestion.topic,
      prompt: lessonQuestion.prompt,
      correctAnswer: lessonQuestion.answer,
      choices: lessonQuestion.options,
    );
  }

  bool _isCorrectChoice(String choice) {
    return choice == question.correctAnswer;
  }

  void _submitChoice(String choice) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();

    setState(() => selectedAnswer = choice);

    if (_isCorrectChoice(choice)) {
      SoundService().playCorrectSound();
      final nextLevelPoints = _levelPoints + 10 + (min(level - 1, 6) * 2);
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
          generateQuestion();
        }
      });
      return;
    }

    _handleIncorrect(choice);
  }

  void _handleTimeout() {
    if (isGameOver) return;
    _handleIncorrect('Time out');
  }

  void _handleIncorrect(String incorrectAnswer) {
    SoundService().playIncorrectSplashSound();
    setState(() {
      selectedAnswer = incorrectAnswer;
      hearts--;
      isGameOver = true;
      showIncorrectSplash = true;
    });

    unawaited(saveScore().catchError((Object error) {
      debugPrint('Error saving $_gameName score: $error');
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
        message: 'Great job! The next level adds more elementary questions.',
        onContinue: () {
          Navigator.pop(context);
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
        correctAnswer: question.correctAnswer,
        heartsRemaining: hearts,
        score: hearts <= 0 ? score : null,
        level: hearts <= 0 ? level : null,
        onRetry: () {
          Navigator.pop(context);
          if (hearts <= 0) {
            startGame();
          } else {
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
          'subject': widget.subject.name,
          if (widget.lessonTitle != null) 'lesson': widget.lessonTitle,
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

      final subjectKey = widget.subject.name;
      final quizKey =
          '${subjectKey}_${_safeScoreKey(widget.lessonTitle ?? 'quiz')}';
      final highscoreKey = '${quizKey}_highscore';
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);

      await GameLogger.logGame(
        gameName: _gameName,
        score: score,
        difficulty: gameDifficultyModeLabel(_selectedMode),
      );

      final snapshot = await userRef.get();
      final previousHighscore = snapshot.data()?[highscoreKey];
      final currentHighscore =
          previousHighscore is num ? previousHighscore.toInt() : 0;

      await userRef.set({
        '${quizKey}_last_score': score,
        '${quizKey}_last_level': level,
        '${quizKey}_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) highscoreKey: score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(
          gameName: _gameName,
          newScore: score,
          difficulty: gameDifficultyModeLabel(_selectedMode),
        );
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
            title: Text(_quizTitle),
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
                isActive: hasStarted &&
                    !isGameOver &&
                    !showCorrectSplash &&
                    !showIncorrectSplash &&
                    !_showExitConfirmation,
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
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
                    message:
                        'Your current progress in this quiz will be saved before leaving.',
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
                    child: IncorrectSplash(
                      duration: _incorrectFeedbackDuration,
                    ),
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
    final config = _config;
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: config.inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: config.inkColor,
        displayColor: config.inkColor,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: config.accentColor,
        secondary: config.accentColor,
        surface: config.panelColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.inkColor,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    final config = _config;
    return AnimatedShapeBackground(
      gradientColors: [config.bgTopColor, config.bgBottomColor],
      shapes: [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topLeft,
          baseOffset: const Offset(-34, -24),
          drift: const Offset(15, 11),
          size: 124,
          color: config.accentColor.withValues(alpha: 0.16),
          borderColor: config.inkColor.withValues(alpha: 0.30),
          initialRotation: -0.16,
          symbol: config.primarySymbol,
          contentColor: config.inkColor,
          contentScale: 0.30,
          cornerRadius: 28,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.topRight,
          baseOffset: const Offset(30, 78),
          drift: const Offset(12, 15),
          size: 104,
          color: const Color(0xFFFF9800).withValues(alpha: 0.16),
          borderColor: config.inkColor.withValues(alpha: 0.26),
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomLeft,
          baseOffset: const Offset(28, 36),
          drift: const Offset(13, 14),
          size: 118,
          color: config.accentColor.withValues(alpha: 0.13),
          borderColor: config.inkColor.withValues(alpha: 0.25),
          symbol: config.secondarySymbol,
          contentColor: config.inkColor,
          contentScale: 0.34,
          cornerRadius: 26,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.diamond,
          alignment: Alignment.bottomRight,
          baseOffset: const Offset(22, 28),
          drift: const Offset(10, 12),
          size: 88,
          color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
          borderColor: config.inkColor.withValues(alpha: 0.24),
          cornerRadius: 20,
          initialRotation: 0.2,
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    final config = _config;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: config.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: config.inkColor, width: 2.2),
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
    final config = _config;
    final description = widget.lessonDescription ?? config.description;
    final topicsSummary = widget.lessonTopicsSummary ?? config.topicsSummary;
    final questionCount = SubjectQuestionBank.questionCountFor(
      widget.subject,
      topics: widget.allowedTopics,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxPanelWidth = responsivePanelMaxWidth(width);

        final gap14 = responsiveCompactGap(width, 14);
        final gap12 = responsiveCompactGap(width, 12);
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
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: config.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: config.accentColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          config.icon,
                          color: config.accentColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _quizTitle,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: gap14),
                  const Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: gap6),
                  DifficultyModeSelector(
                    selected: _selectedMode,
                    accentColor: config.accentColor,
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
                        color: config.inkColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$topicsSummary\n$questionCount questions rotate with level difficulty.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (_isOffline) ...[
                    SizedBox(height: gap14),
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
                              'No connection detected. This lesson still plays offline, but your progress stays on the device until you reconnect.',
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
                      label: Text('Start $_quizTitle'),
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

  Widget _buildGameUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = constraints.maxWidth > 700 ? 760.0 : 560.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _card(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Score: $score',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        'Level: $level',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      HeartsDisplay(hearts: hearts),
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
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      _buildQuestionCard(),
                      const SizedBox(height: 12),
                      ...question.choices.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildChoiceButton(
                            label: String.fromCharCode(65 + entry.key),
                            answer: entry.value,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard() {
    final config = _config;
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: config.accentColor.withValues(alpha: 0.14),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Words in the question are tappable: tapping one looks it up in the
          // dictionary API so a student who is only blocked by vocabulary can
          // unblock themselves without leaving the quiz.
          TappableWordText(
            text: question.prompt,
            onWordTap: _lookUpWord,
            highlightColor: config.accentColor,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 14, color: config.accentColor.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                'Tap an underlined word to see what it means',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: config.accentColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens the dictionary lookup sheet for [word].
  ///
  /// The quiz timer keeps running, so this is a help affordance rather than a
  /// pause button — looking up a word costs the student time, same as thinking
  /// about it would.
  Future<void> _lookUpWord(String word) async {
    if (isGameOver || !hasStarted) return;
    SoundService().playButtonSoundNow();

    final config = _config;
    await WordLookupSheet.show(
      context,
      word: word,
      inkColor: config.inkColor,
      accentColor: config.accentColor,
      panelColor: config.panelColor,
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required String answer,
  }) {
    final config = _config;
    final isSelected = selectedAnswer == answer;
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isGameOver ? null : () => _submitChoice(answer),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: isSelected ? config.inkColor : config.accentColor,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(isWideScreen ? 72 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 18 : 14,
            vertical: isWideScreen ? 16 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: config.inkColor, width: 2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.42),
                  width: 1.4,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
