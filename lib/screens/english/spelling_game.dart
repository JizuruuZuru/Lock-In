import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../../services/connectivity_service.dart';
import '../../services/face_proctor_service.dart';
import '../../services/game_logger.dart';
import '../../services/leaderboard_service.dart';
import '../../services/leave_attempt_logger.dart';
import '../../services/sound_service.dart';
import '../../services/text_to_speech_service.dart';
import '../../utils/game_difficulty_mode.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/alphabet_keyboard.dart';
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

class _SpellingWord {
  final String word;
  final String sentence;
  final int minLevel;

  const _SpellingWord({
    required this.word,
    required this.sentence,
    required this.minLevel,
  });

  String get sentenceWithBlank {
    final blank = '_' * word.length;
    final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
    return sentence.replaceAll(pattern, blank);
  }
}

const _spellingWords = <_SpellingWord>[
  _SpellingWord(word: 'cat', sentence: 'The cat slept on the mat.', minLevel: 1),
  _SpellingWord(word: 'dog', sentence: 'The dog ran in the park.', minLevel: 1),
  _SpellingWord(word: 'book', sentence: 'She read a book before bed.', minLevel: 1),
  _SpellingWord(word: 'tree', sentence: 'A bird landed on the tree.', minLevel: 1),
  _SpellingWord(word: 'jump', sentence: 'The frog can jump very high.', minLevel: 1),
  _SpellingWord(word: 'happy', sentence: 'She felt happy on her birthday.', minLevel: 1),
  _SpellingWord(word: 'friend', sentence: 'My best friend moved next door.', minLevel: 2),
  _SpellingWord(word: 'school', sentence: 'We walk to school every morning.', minLevel: 2),
  _SpellingWord(word: 'garden', sentence: 'Dad grows tomatoes in the garden.', minLevel: 2),
  _SpellingWord(word: 'purple', sentence: 'She painted the wall purple.', minLevel: 2),
  _SpellingWord(word: 'monkey', sentence: 'The monkey swung from branch to branch.', minLevel: 2),
  _SpellingWord(word: 'people', sentence: 'Many people waited for the bus.', minLevel: 2),
  _SpellingWord(word: 'because', sentence: 'I stayed inside because it was raining.', minLevel: 3),
  _SpellingWord(word: 'beautiful', sentence: 'The sunset was beautiful tonight.', minLevel: 3),
  _SpellingWord(word: 'favorite', sentence: 'Pizza is my favorite food.', minLevel: 3),
  _SpellingWord(word: 'different', sentence: 'Each snowflake looks different.', minLevel: 3),
  _SpellingWord(word: 'important', sentence: 'It is important to wash your hands.', minLevel: 3),
  _SpellingWord(word: 'together', sentence: 'The whole class sang together.', minLevel: 3),
  _SpellingWord(word: 'necessary', sentence: 'A helmet is necessary for biking.', minLevel: 4),
  _SpellingWord(word: 'mountain', sentence: 'Snow covered the tall mountain.', minLevel: 4),
  _SpellingWord(word: 'celebrate', sentence: 'We will celebrate her birthday on Friday.', minLevel: 4),
  _SpellingWord(word: 'dictionary', sentence: 'Look up the word in a dictionary.', minLevel: 4),
  _SpellingWord(word: 'experiment', sentence: 'The class did a science experiment.', minLevel: 4),
  _SpellingWord(word: 'vegetable', sentence: 'Carrots are a healthy vegetable.', minLevel: 4),
  _SpellingWord(word: 'bed', sentence: 'I make my bed every morning.', minLevel: 1),
  _SpellingWord(word: 'frog', sentence: 'A frog jumped into the pond.', minLevel: 1),
  _SpellingWord(word: 'milk', sentence: 'She poured milk into her cereal.', minLevel: 1),
  _SpellingWord(word: 'rain', sentence: 'The rain tapped gently on the roof.', minLevel: 1),
  _SpellingWord(word: 'bike', sentence: 'He rode his bike to the park.', minLevel: 1),
  _SpellingWord(word: 'nest', sentence: 'The bird built a nest in the tree.', minLevel: 1),
  _SpellingWord(word: 'sand', sentence: 'We built a castle out of sand.', minLevel: 1),
  _SpellingWord(word: 'gift', sentence: 'Her grandmother wrapped the gift in blue paper.', minLevel: 1),
  _SpellingWord(word: 'plant', sentence: 'Water the plant twice a week.', minLevel: 1),
  _SpellingWord(word: 'clock', sentence: 'The clock on the wall struck noon.', minLevel: 1),
  _SpellingWord(word: 'snack', sentence: 'I packed a snack for the field trip.', minLevel: 1),
  _SpellingWord(word: 'brush', sentence: 'Use this brush to clean your teeth.', minLevel: 1),
  _SpellingWord(word: 'cloud', sentence: 'A fluffy cloud drifted across the sky.', minLevel: 1),
  _SpellingWord(word: 'spoon', sentence: 'She stirred the soup with a spoon.', minLevel: 1),
  _SpellingWord(word: 'planet', sentence: 'Earth is the planet where we live.', minLevel: 2),
  _SpellingWord(word: 'animal', sentence: 'Every animal in the zoo needs fresh water.', minLevel: 2),
  _SpellingWord(word: 'pencil', sentence: 'He sharpened his pencil before the test.', minLevel: 2),
  _SpellingWord(word: 'bottle', sentence: 'Fill the bottle with cold water.', minLevel: 2),
  _SpellingWord(word: 'rocket', sentence: 'The rocket blasted off into space.', minLevel: 2),
  _SpellingWord(word: 'castle', sentence: 'Knights once lived inside that castle.', minLevel: 2),
  _SpellingWord(word: 'yellow', sentence: 'The sun looked bright yellow this morning.', minLevel: 2),
  _SpellingWord(word: 'blanket', sentence: 'She wrapped herself in a cozy blanket.', minLevel: 2),
  _SpellingWord(word: 'picture', sentence: 'He hung a picture of his dog on the wall.', minLevel: 2),
  _SpellingWord(word: 'journey', sentence: 'Our journey to the mountains took five hours.', minLevel: 2),
  _SpellingWord(word: 'whisper', sentence: 'She began to whisper so no one else could hear.', minLevel: 2),
  _SpellingWord(word: 'thunder', sentence: 'The thunder rumbled loudly during the storm.', minLevel: 2),
  _SpellingWord(word: 'kitchen', sentence: 'Mom is cooking dinner in the kitchen.', minLevel: 2),
  _SpellingWord(word: 'calendar', sentence: 'She circled her birthday on the calendar.', minLevel: 3),
  _SpellingWord(word: 'building', sentence: 'The tallest building in the city has fifty floors.', minLevel: 3),
  _SpellingWord(word: 'sandwich', sentence: 'He packed a turkey sandwich for lunch.', minLevel: 3),
  _SpellingWord(word: 'exercise', sentence: 'Daily exercise keeps your body healthy.', minLevel: 3),
  _SpellingWord(word: 'treasure', sentence: 'The pirates buried their treasure on the island.', minLevel: 3),
  _SpellingWord(word: 'sentence', sentence: 'Write a complete sentence with a subject and a verb.', minLevel: 3),
  _SpellingWord(word: 'umbrella', sentence: 'She grabbed her umbrella before the rain started.', minLevel: 3),
  _SpellingWord(word: 'hospital', sentence: 'The nurse works at the hospital downtown.', minLevel: 3),
  _SpellingWord(word: 'vacation', sentence: 'Our family is planning a vacation to the beach.', minLevel: 3),
  _SpellingWord(word: 'dinosaur', sentence: 'The museum displayed a giant dinosaur skeleton.', minLevel: 3),
  _SpellingWord(word: 'neighbor', sentence: 'Our neighbor waved to us from across the street.', minLevel: 3),
  _SpellingWord(word: 'triangle', sentence: 'A triangle has exactly three sides.', minLevel: 3),
  _SpellingWord(word: 'costume', sentence: 'She wore a butterfly costume for the parade.', minLevel: 3),
  _SpellingWord(word: 'library', sentence: 'We borrowed three books from the library.', minLevel: 3),
  _SpellingWord(word: 'wilderness', sentence: 'The hikers camped deep in the wilderness.', minLevel: 4),
  _SpellingWord(word: 'temperature', sentence: 'The temperature dropped suddenly after sunset.', minLevel: 4),
  _SpellingWord(word: 'discovery', sentence: 'Scientists announced an exciting new discovery.', minLevel: 4),
  _SpellingWord(word: 'instrument', sentence: 'She learned to play a musical instrument.', minLevel: 4),
  _SpellingWord(word: 'explanation', sentence: 'The teacher gave a clear explanation of the problem.', minLevel: 4),
  _SpellingWord(word: 'adventure', sentence: 'They set off on an exciting adventure through the forest.', minLevel: 4),
  _SpellingWord(word: 'knowledge', sentence: 'Reading books helps build your knowledge.', minLevel: 4),
  _SpellingWord(word: 'immediately', sentence: 'He immediately raised his hand to answer.', minLevel: 4),
  _SpellingWord(word: 'curiosity', sentence: 'Her curiosity led her to explore the old attic.', minLevel: 4),
  _SpellingWord(word: 'government', sentence: 'The government built a new bridge across the river.', minLevel: 4),
  _SpellingWord(word: 'gymnasium', sentence: 'The students practiced basketball in the gymnasium.', minLevel: 4),
  _SpellingWord(word: 'embarrass', sentence: 'He did not want to embarrass himself during the speech.', minLevel: 4),
  _SpellingWord(word: 'mysterious', sentence: 'A mysterious noise came from the basement.', minLevel: 4),
];

class EnglishSpellingGame extends StatefulWidget {
  const EnglishSpellingGame({super.key});

  @override
  State<EnglishSpellingGame> createState() => _EnglishSpellingGameState();
}

class _EnglishSpellingGameState extends State<EnglishSpellingGame> {
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1600);

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
  int timeLimit = 35;
  List<String> typedLetters = [];
  Key timerKey = UniqueKey();
  late _SpellingWord currentWord;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  // Tracks which words this session has already served, so the same word
  // doesn't repeat until every eligible one has been asked.
  final Set<String> _askedWords = {};

  SubjectQuizConfig get _config =>
      SubjectQuestionBank.configFor(SubjectQuizType.english);
  static const String _gameName = 'English: Spelling';

  String get _typedInput => typedLetters.join();

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
    SoundService().playPageBgm(BgmPage.english);
    SoundService().registerUserInteraction();
    _refreshOfflineState();
  }

  @override
  void dispose() {
    GameLogger.endSession();
    TextToSpeechService().stop();
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
      typedLetters = [];
      timerKey = UniqueKey();
      _askedWords.clear();
    });
    generateQuestion();
  }

  int _timeLimitForLevel() => (38 - min(level, 8) * 2).clamp(20, 36);

  void generateQuestion() {
    final eligible = _spellingWords.where((w) => w.minLevel <= level).toList();
    final pool = eligible.isEmpty ? _spellingWords : eligible;
    final unseen = pool.where((w) => !_askedWords.contains(w.word)).toList();
    final candidates = unseen.isEmpty ? pool : unseen;
    final next = candidates[_random.nextInt(candidates.length)];
    _askedWords.add(next.word);

    setState(() {
      currentWord = next;
      typedLetters = [];
      isGameOver = false;
      timerKey = UniqueKey();
      timeLimit = _timeLimitForLevel();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentWord());
  }

  Future<void> _speakCurrentWord() async {
    await TextToSpeechService().speak(currentWord.word);
  }

  void _replaySound() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    _speakCurrentWord();
  }

  void _onLetterTap(String letter) {
    if (isGameOver) return;
    if (typedLetters.length >= currentWord.word.length + 4) return;
    setState(() => typedLetters.add(letter));
  }

  void _onBackspace() {
    if (isGameOver || typedLetters.isEmpty) return;
    SoundService().playButtonSoundNow();
    setState(() => typedLetters.removeLast());
  }

  void _onSubmit() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    if (typedLetters.isEmpty) return;

    final isCorrect = _typedInput.toLowerCase() == currentWord.word.toLowerCase();
    if (isCorrect) {
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

    _handleIncorrect(_typedInput);
  }

  void _handleTimeout() {
    if (isGameOver) return;
    _handleIncorrect(_typedInput.isEmpty ? 'No answer' : _typedInput);
  }

  void _handleIncorrect(String incorrectAnswer) {
    SoundService().playIncorrectSplashSound();
    setState(() {
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
        message: 'Great job! The next level uses longer spelling words.',
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
        correctAnswer: currentWord.word,
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
        details: {'score': score, 'level': level},
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

      final quizKey = 'english_${_safeScoreKey('spelling')}';
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
            title: const Text('Spelling'),
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
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
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
          BoxShadow(color: Color(0x332C3550), offset: Offset(5, 6), blurRadius: 0),
        ],
      ),
      child: child,
    );
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
                          color: _config.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _config.accentColor, width: 2),
                        ),
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: _config.accentColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Spelling',
                          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap12),
                  const Text(
                    'Listen to the word, then spell it using the keyboard below. Tap the speaker to hear it again.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: gap14),
                  const Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: gap6),
                  DifficultyModeSelector(
                    selected: _selectedMode,
                    accentColor: _config.accentColor,
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
                        color: _config.inkColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'Everyday spelling words that get longer and trickier as you level up.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.35),
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
                        border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Color(0xFFE65100)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No connection detected. This lesson still plays offline, but your progress stays on the device until you reconnect.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
                      label: const Text('Start Spelling'),
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            Size.fromHeight(responsiveButtonHeight(MediaQuery.sizeOf(context).width)),
                        padding: EdgeInsets.symmetric(
                          vertical: responsiveButtonHeight(MediaQuery.sizeOf(context).width) / 2.4,
                        ),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
        final maxContentWidth = responsivePanelMaxWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _card(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Score: $score',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        'Level: $level',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
                      _buildWordCard(),
                      const SizedBox(height: 14),
                      _buildLetterSlots(),
                      const SizedBox(height: 18),
                      AlphabetKeyboard(
                        onLetterTap: _onLetterTap,
                        onBackspace: _onBackspace,
                        onSubmit: _onSubmit,
                        isDisabled: isGameOver,
                        accentColor: _config.accentColor,
                        inkColor: _config.inkColor,
                      ),
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

  Widget _buildWordCard() {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _config.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Spelling',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentWord.sentenceWithBlank,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 64,
            height: 64,
            child: ElevatedButton(
              onPressed: isGameOver ? null : _replaySound,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: _config.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                elevation: 3,
              ),
              child: const Icon(Icons.volume_up_rounded, size: 32),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to hear the word again',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterSlots() {
    final letters = typedLetters;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < max(letters.length, currentWord.word.length); i++)
          Container(
            width: 38,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _config.inkColor, width: 2),
            ),
            child: Text(
              i < letters.length ? letters[i] : '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}
