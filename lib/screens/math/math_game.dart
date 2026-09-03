import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/player_proctoring_preference.dart';
import '../../services/game_result_recorder.dart';
import '../../services/leaderboard_service.dart';
import '../../services/game_logger.dart';

import '../../services/face_proctor_contract.dart';
import '../../services/face_proctor_service.dart';
import '../../services/leave_attempt_logger.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/game_difficulty_mode.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/correct_splash.dart';
import '../../widgets/game_over_popup.dart';
import '../../widgets/level_up_popup.dart';
import '../../widgets/hearts_display.dart';
import '../../widgets/incorrect_splash.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/difficulty_mode_selector.dart';
import '../../widgets/app_brightness_overlay.dart'; 
import '../../widgets/game_timer.dart';
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/number_pad.dart';

enum MathMode { add, subtract, multiply, divide, random }

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> with WidgetsBindingObserver {
  static const Color _inkColor = Color(0xFF2C1B47);
  static const Color _bgTopColor = Color(0xFFFFF4E6);
  static const Color _bgBottomColor = Color(0xFFFFE0D6);
  static const Color _panelColor = Color(0xFFF0F8FF);
  static const Color _accentColor = Color(0xFF9C27B0);
  static const int _autoSubmitAfterLeaves = 1;

  MathMode? selectedMode;
  MathMode? pendingMode;

  int score = 0;
  int level = 1;
  int previousLevel = 1;
  int timeLimit = 10;

  int correctAnswer = 0;
  String question = '';
  String input = '';

  Key timerKey = UniqueKey();
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  int hearts = 3;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  bool _didLeaveApp = false;
  bool _processingLeaveAttempt = false;
  bool _showLeaveWarning = false;
  bool _showExitConfirmation = false;
  bool _suspendLeaveDetector = false;
  String _leaveWarningMessage =
      'You have left the app. The game will restart.';
  int _leaveAttemptsThisRun = 0;
  bool _faceSupportNoticeShown = false;
  final FaceProctorService _faceProctor = createFaceProctorService();
  bool _isProctorActive = false;

  /// Whether the camera is actually watching this run.
  ///
  /// Starts false and is set true only by a clean camera start, so the saved
  /// score - and the leaderboard badge it feeds - tells the truth in every
  /// case: the teacher switched proctoring off, the player declined the
  /// camera in their own settings, or it could not be opened.
  bool _runProctored = false;

  /// The pause between answering and the next round.
  ///
  /// Was an un-cancellable `Future.delayed`. Its callback starts the next
  /// round - clearing `isGameOver` and minting a fresh `timerKey` - so a face
  /// violation, an app-background, or a tap on Back landing inside that window
  /// put a warning overlay on screen with a live round running underneath it.
  /// Cancelled whenever an overlay goes up, and on dispose.
  Timer? _feedbackTimer;

  // 🔥 duplicate prevention
  bool _isSavingScore = false;

  static String _gameNameFor(MathMode mode) => 'Math Game (${mode.name})';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    // Ends only this screen's session. Passing no name would clear every
    // game's, including one still open underneath this route.
    final mode = selectedMode;
    if (mode != null) GameLogger.endSession(_gameNameFor(mode));
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopFaceProctor());
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  Future<void> _stopFaceProctor() async {
    if (_isProctorActive) {
      await _faceProctor.stop();
      _isProctorActive = false;
    }
  }

  Future<bool> _startFaceProctor() async {
    if (selectedMode == null) return false;
    if (!faceProctorEnabledFor(isExam: false)) return false;
    if (_isProctorActive) return true;

    // Claimed before the await. `start()` takes hundreds of milliseconds on
    // mobile, and `dispose()` during that window used to find this flag still
    // false, so `_stopFaceProctor()` no-opped and the camera and ML Kit
    // detector stayed live after the screen was gone. Setting it here also
    // stops two concurrent starts building two CameraControllers.
    _isProctorActive = true;

    final FaceProctorStartStatus status;
    try {
      status = await _faceProctor.start(
        absenceThreshold: const Duration(seconds: 3),
        onViolation: (event) {
          _handleFaceViolation(
            gameName: _gameNameFor(selectedMode!),
            event: event,
          );
        },
      );
    } catch (_) {
      _isProctorActive = false;
      rethrow;
    }

    if (status == FaceProctorStartStatus.started) {
      if (!mounted) {
        // Unmounted mid-start; nothing else will release the camera.
        await _faceProctor.stop();
        _isProctorActive = false;
        return false;
      }
      return true;
    }

    _isProctorActive = false;
    return false;
  }

  Future<void> startGame(MathMode mode) async {
    await _stopFaceProctor();

    // Reset before the check below, not in the setState after it: the check is
    // what decides whether the camera actually opens, and clearing the flag
    // afterwards would throw that answer away.
    _runProctored = false;

    final monitoringReady = await _ensureFaceMonitoringForMode(mode);
    if (!monitoringReady || !mounted) return;

    // Start new game session for logging
    GameLogger.startNewSession('Math Game (${mode.name})');

    setState(() {
      pendingMode = null;
      selectedMode = mode;
      score = 0;
      level = 1;
      previousLevel = 1;
      input = '';
      timerKey = UniqueKey();
      isGameOver = false;
      hearts = gameDifficultyModeHearts(_selectedMode);
      _didLeaveApp = false;
      _processingLeaveAttempt = false;
      _showLeaveWarning = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _leaveAttemptsThisRun = 0;
      _isSavingScore = false; // reset flag
    });
    generateQuestion();
    // Deliberately not set here. `_ensureFaceMonitoringForMode` already
    // reports the truth: it returns true for `unsupportedPlatform` so web and
    // desktop can still play, but nothing was started there. Re-asserting the
    // flag afterwards made it claim proctoring was running on every platform.
  }

  Future<bool> _ensureFaceMonitoringForMode(MathMode mode) async {
    // Either the teacher switched lesson proctoring off for the whole class,
    // or this player turned the camera off in their own settings. Nothing is
    // opened, and `_runProctored` stays false, so the score records that the
    // camera was not watching.
    if (!faceProctorEnabledFor(isExam: false)) return true;

    // Claimed before the await for the same reason as _startFaceProctor: this
    // takes hundreds of milliseconds, and a dispose during that window used to
    // leave the camera running with nothing left to stop it.
    _isProctorActive = true;

    final FaceProctorStartStatus status;
    try {
      status = await _faceProctor.start(
        absenceThreshold: const Duration(seconds: 3),
        onViolation: (event) {
          _handleFaceViolation(
            gameName: _gameNameFor(mode),
            event: event,
          );
        },
      );
    } catch (_) {
      _isProctorActive = false;
      rethrow;
    }

    if (!mounted) {
      await _faceProctor.stop();
      _isProctorActive = false;
      return false;
    }

    if (status != FaceProctorStartStatus.started) {
      _isProctorActive = false;
    }

    switch (status) {
      case FaceProctorStartStatus.started:
        _runProctored = true;
        return true;
      case FaceProctorStartStatus.unsupportedPlatform:
        if (!_faceSupportNoticeShown) {
          _faceSupportNoticeShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Face detection anti-cheat is available only on Android/iOS.',
              ),
            ),
          );
        }
        return true;
      // These three used to return false, which aborted `startGame` outright -
      // so declining the camera prompt once left the player staring at a start
      // screen that would never start. Being unable to watch somebody is not a
      // reason to stop them playing; the round runs and is recorded as
      // unwatched instead.
      case FaceProctorStartStatus.permissionDenied:
        _reportProctoringUnavailable(
          'Camera permission was declined, so this round is not being watched.',
        );
        return true;
      case FaceProctorStartStatus.noFrontCamera:
        _reportProctoringUnavailable(
          'No front camera on this device, so this round is not being watched.',
        );
        return true;
      case FaceProctorStartStatus.initializationFailed:
        _reportProctoringUnavailable(
          'Face detection could not start, so this round is not being watched.',
        );
        return true;
    }
  }

  /// Tells the player once and flags the run, without stopping it.
  void _reportProctoringUnavailable(String message) {
    if (!mounted) return;
    // Do not retry for the rest of this screen's life, or a declined
    // permission would re-prompt on every pause/resume cycle.
    _faceSupportNoticeShown = true;
    _runProctored = false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isRoundActive() {
    return selectedMode != null &&
        !isGameOver &&
        !showCorrectSplash &&
        !showIncorrectSplash &&
        !_showLeaveWarning &&
        !_showExitConfirmation &&
        !_suspendLeaveDetector;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_suspendLeaveDetector) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_stopFaceProctor());
      _didLeaveApp = true;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_didLeaveApp) {
        _didLeaveApp = false;
        _handleLeaveAttempt();
      }
    }
  }

  Future<void> _handleLeaveAttempt() async {
    if (_suspendLeaveDetector ||
        _processingLeaveAttempt ||
        (!_isRoundActive() && !_showExitConfirmation)) {
      return;
    }

    _processingLeaveAttempt = true;
    _leaveAttemptsThisRun++;

    if (_leaveAttemptsThisRun < _autoSubmitAfterLeaves) {
      _processingLeaveAttempt = false;
      return;
    }

    final currentMode = selectedMode;
    if (currentMode == null) {
      _processingLeaveAttempt = false;
      return;
    }

    await _stopFaceProctor();

    // Stopping the proctor tears down the camera and the ML Kit detector,
    // which is slow enough that the player can leave the screen first.
    if (!mounted) {
      _processingLeaveAttempt = false;
      return;
    }

    setState(() {
      isGameOver = true;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      // Drop any pending "next round" callback, or it will restart
      // the round behind this overlay.
      _feedbackTimer?.cancel();
      _showLeaveWarning = true;
      _showExitConfirmation = false;
      _suspendLeaveDetector = true;
      _leaveWarningMessage = 'You have left the app. The game will restart.';
    });

    try {
      // Bounded, because `isBusy: _processingLeaveAttempt` disables both
      // Stay and Leave on the warning overlay while this runs. A Firestore
      // write future only completes on server acknowledgement, so offline
      // this never returned and the overlay sat there with both buttons
      // greyed out - no way back into the game and no way out of it.
      //
      // Issued together rather than in sequence so the score save still
      // reaches the local cache when the log write is the one hanging.
      await saveBeforeLeaving(() async {
        await Future.wait<void>([
          LeaveAttemptLogger.logAttempt(
            gameName: _gameNameFor(currentMode),
            reason: 'app_backgrounded_or_home_pressed',
          ),
          saveScore(),
        ]);
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingLeaveAttempt = false;
        });
      }
    }
  }

  Future<void> _handleFaceViolation({
    required String gameName,
    required FaceViolationEvent event,
  }) async {
    if (_suspendLeaveDetector || _processingLeaveAttempt || !_isRoundActive()) {
      return;
    }

    _processingLeaveAttempt = true;
    await _stopFaceProctor();

    if (mounted) {
      setState(() {
        isGameOver = true;
        showCorrectSplash = false;
        showIncorrectSplash = false;
        // Drop any pending "next round" callback, or it will restart
        // the round behind this overlay.
        _feedbackTimer?.cancel();
        _showLeaveWarning = true;
        _showExitConfirmation = false;
        _suspendLeaveDetector = true;
        _leaveWarningMessage = _faceViolationMessage(event.reason);
      });
    }

    try {
      // Bounded, because `isBusy: _processingLeaveAttempt` disables both
      // Stay and Leave on the warning overlay while this runs. A Firestore
      // write future only completes on server acknowledgement, so offline
      // this never returned and the overlay sat there with both buttons
      // greyed out - no way back into the game and no way out of it.
      //
      // Issued together rather than in sequence so the score save still
      // reaches the local cache when the log write is the one hanging.
      await saveBeforeLeaving(() async {
        await Future.wait<void>([
          LeaveAttemptLogger.logAttempt(
            gameName: gameName,
            reason: _faceViolationReasonTag(event.reason),
            source: 'face_detector',
            details: {
              'seconds_without_valid_face': event.secondsWithoutValidFace,
            },
          ),
          saveScore(),
        ]);
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingLeaveAttempt = false;
        });
      }
    }
  }

  String _faceViolationReasonTag(FaceViolationReason reason) {
    switch (reason) {
      case FaceViolationReason.noFaceDetected:
        return 'face_not_detected_for_3_seconds';
      case FaceViolationReason.notFacingDevice:
        return 'face_not_facing_device_for_3_seconds';
    }
  }

  String _faceViolationMessage(FaceViolationReason reason) {
    switch (reason) {
      case FaceViolationReason.noFaceDetected:
        return 'You have left the camera view for 3 seconds. The game will restart.';
      case FaceViolationReason.notFacingDevice:
        return 'You are not facing the camera. The game will restart.';
    }
  }

  void _restartFromLeaveWarning() {
    if (_processingLeaveAttempt) return;
    final currentMode = selectedMode;
    if (currentMode == null) return;

    setState(() {
      _showLeaveWarning = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _didLeaveApp = false;
      _leaveAttemptsThisRun = 0;
    });
    startGame(currentMode);
  }

  void _backFromLeaveWarning() {
    if (_processingLeaveAttempt) return;

    unawaited(_stopFaceProctor());
    setState(() {
      _showLeaveWarning = false;
      selectedMode = null;
      pendingMode = null;
      score = 0;
      level = 1;
      previousLevel = 1;
      input = '';
      question = '';
      correctAnswer = 0;
      hearts = gameDifficultyModeHearts(_selectedMode);
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _didLeaveApp = false;
      _leaveAttemptsThisRun = 0;
    });
  }

  bool _shouldConfirmExit() {
    return _isRoundActive();
  }

  void _showExitConfirmationOverlay() {
    if (_showExitConfirmation || !_shouldConfirmExit()) return;

    unawaited(_stopFaceProctor());

    setState(() {
      // No feedback timer to cancel here: `_shouldConfirmExit()` above is
      // false while a correct/incorrect splash is up, so this overlay cannot
      // open inside the feedback window in the first place.
      _showExitConfirmation = true;
      isGameOver = true;
    });
  }

  void _cancelExitConfirmation() {
    if (!_showExitConfirmation) return;

    setState(() {
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      isGameOver = false;
    });

    if (selectedMode != null && !isGameOver) {
      unawaited(_startFaceProctor());
    }
  }

  Future<void> _confirmExitFromBack() async {
    if (_processingLeaveAttempt) return;

    // Best-effort: a camera that refuses to release must not strand the player
    // on a screen they asked to leave.
    try {
      await _stopFaceProctor();
    } catch (error) {
      debugPrint('Could not release the camera while leaving: $error');
    }

    // The other ten games record the walk-out; this screen did not, so a
    // player who left a round mid-way left no trace at all. The score is
    // deliberately *not* saved here - the dialog above this button says the
    // progress will be lost, and it should keep telling the truth.
    final mode = selectedMode;
    if (mode != null) {
      // Bounded: a Firestore write future only completes on server
      // acknowledgement, so awaiting one offline is what stops an exit button
      // responding at all. See saveBeforeLeaving.
      await saveBeforeLeaving(() => LeaveAttemptLogger.logAttempt(
            gameName: _gameNameFor(mode),
            reason: 'player_pressed_back_while_playing',
            source: 'back_button',
            details: {
              'score': score,
              'level': level,
            },
          ));
    }

    if (!mounted) return;

    // `Navigator.pop`, not `maybePop`. This screen's `PopScope(canPop: false)`
    // hands `maybePop` straight back to `_onAppBarBackPressed`, which then
    // returns immediately because `_showExitConfirmation` is still true - so
    // the Leave button did nothing whatsoever.
    Navigator.pop(context);
  }

  Future<void> _onAppBarBackPressed() async {
    if (_processingLeaveAttempt || _showLeaveWarning || _showExitConfirmation) {
      return;
    }
    SoundService().playButtonSoundNow();

    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    // `Navigator.pop`, not `maybePop`. This screen's own
    // `PopScope(canPop: false)` intercepts `maybePop` and calls this handler
    // again, which calls `maybePop` again - an endless loop, so the back arrow
    // never left the mode panel.
    Navigator.pop(context);
  }

  String modeDisplayName(MathMode mode) {
    switch (mode) {
      case MathMode.add:
        return 'Addition';
      case MathMode.subtract:
        return 'Subtraction';
      case MathMode.multiply:
        return 'Multiplication';
      case MathMode.divide:
        return 'Division';
      case MathMode.random:
        return 'Random';
    }
  }

  bool updateLevel() {
    previousLevel = level;
    level = (score ~/ 5) + 1;
    timeLimit = max(10 - level, 3);
    return level > previousLevel;
  }

  List<int> generateNumbers(int count, int maxNumber) {
    final rand = Random();
    return List.generate(count, (_) => rand.nextInt(maxNumber) + 1);
  }

  String generateRandomQuestion(int numbersCount, int maxNumber) {
    final rand = Random();
    final operators = ['+', '-', 'x', '÷'];
    
    // Start with random numbers
    final numbers = List.generate(numbersCount, (_) => rand.nextInt(maxNumber) + 1);
    final ops = List.generate(numbersCount - 1, (_) => operators[rand.nextInt(4)]);
    
    // Fix divisions to have no remainders with progressive difficulty
    for (int i = 0; i < ops.length; i++) {
      if (ops[i] == '÷') {
        // Scale division difficulty with level
        int quotientMax;
        if (level <= 3) {
          quotientMax = 10;
        } else if (level <= 6) {
          quotientMax = 15;
        } else if (level <= 10) {
          quotientMax = 20;
        } else if (level <= 20) {
          quotientMax = 30;
        } else {
          quotientMax = 50;
        }
        
        int divisor = numbers[i + 1];
        if (divisor == 0 || divisor == 1) {
          divisor = rand.nextInt(9) + 2; // 2-10
          numbers[i + 1] = divisor;
        }
        
        // Make the division clean by ensuring dividend is divisible by divisor
        final quotient = rand.nextInt(quotientMax) + 1;
        numbers[i] = divisor * quotient;
      }
    }
    
    // Calculate the correct answer
    int result = numbers[0];
    for (int i = 1; i < numbersCount; i++) {
      switch (ops[i - 1]) {
        case '+':
          result += numbers[i];
          break;
        case '-':
          result -= numbers[i];
          break;
        case 'x':
          result *= numbers[i];
          break;
        case '÷':
          result = result ~/ numbers[i]; // integer division
          break;
      }
    }
    
    correctAnswer = result;
    String questionText = numbers[0].toString();
    for (int i = 1; i < numbersCount; i++) {
      questionText += ' ${ops[i - 1]} ${numbers[i]}';
    }
    return '$questionText = ?';
  }

  void generateQuestion() {
    final rand = Random();
    final leveledUp = updateLevel();

    int maxNumber;
    if (level <= 3) {
      maxNumber = 10;
    } else if (level <= 6) {
      maxNumber = 20;
    } else if (level <= 10) {
      maxNumber = 50;
    } else if (level <= 20) {
      maxNumber = 100;
    } else if (level <= 30) {
      maxNumber = 1000;
    } else {
      maxNumber = 10000;
    }

    int numbersCount = 2;
    if (level >= 2 && level < 4) {
      numbersCount = 3;
    } else if (level >= 4 && level < 7) {
      numbersCount = 4;
    } else if (level >= 7) {
      numbersCount = 5;
    }

    final numbers = generateNumbers(numbersCount, maxNumber);

    switch (selectedMode!) {
      case MathMode.add:
        correctAnswer = numbers.reduce((a, b) => a + b);
        question = '${numbers.join(' + ')} = ?';
        break;

      case MathMode.subtract:
        // ✅ Fixed: Start with first number, then subtract the rest
        correctAnswer = numbers[0];
        for (int i = 1; i < numbers.length; i++) {
          correctAnswer -= numbers[i];
        }
        question = '${numbers.join(' - ')} = ?';
        break;

      case MathMode.multiply:
        correctAnswer = numbers.reduce((a, b) => a * b);
        question = '${numbers.join(' x ')} = ?';
        break;

      case MathMode.divide:
        // ✅ Progressive difficulty: Division gets harder as level increases
        int divisorMin, divisorMax, quotientMax;
        
        if (level <= 3) {
          // Level 1-3: Easy (e.g., 12 ÷ 3, 20 ÷ 4)
          divisorMin = 2;
          divisorMax = 5;
          quotientMax = 10;
        } else if (level <= 6) {
          // Level 4-6: Medium (e.g., 56 ÷ 7, 72 ÷ 8)
          divisorMin = 3;
          divisorMax = 9;
          quotientMax = 15;
        } else if (level <= 10) {
          // Level 7-10: Hard (e.g., 144 ÷ 12, 180 ÷ 15)
          divisorMin = 6;
          divisorMax = 15;
          quotientMax = 20;
        } else if (level <= 20) {
          // Level 11-20: Very Hard (e.g., 420 ÷ 21, 540 ÷ 27)
          divisorMin = 10;
          divisorMax = 30;
          quotientMax = 30;
        } else if (level <= 30) {
          // Level 21-30: Expert (e.g., 1440 ÷ 48, 2100 ÷ 60)
          divisorMin = 20;
          divisorMax = 60;
          quotientMax = 50;
        } else {
          // Level 31+: Master (e.g., 4800 ÷ 96, 7200 ÷ 120)
          divisorMin = 40;
          divisorMax = 120;
          quotientMax = 100;
        }
        
        final divisor = rand.nextInt(divisorMax - divisorMin + 1) + divisorMin;
        final quotient = rand.nextInt(quotientMax) + 1;
        final dividend = divisor * quotient; // perfect division!
        
        correctAnswer = quotient;
        question = '$dividend ÷ $divisor = ?';
        break;

      case MathMode.random:
        question = generateRandomQuestion(numbersCount, maxNumber);
        break;
    }

    input = '';
    setState(() {
      timerKey = UniqueKey();
      isGameOver = false;
    });

    if (leveledUp) {
      unawaited(_stopFaceProctor());
      showLevelUpPage();
    }
  }

  /// 🔹 Append digit or handle minus sign for negative input
  void appendInput(String value) {
    if (isGameOver) return;
    setState(() {
      if (value == '-') {
        // Only allow a leading minus sign
        if (input.isEmpty) {
          input = '-';
        } else if (input.startsWith('-')) {
          // Already has minus – optionally remove it (toggle)
          input = input.substring(1);
        } else {
          // Prepend minus
          input = '-$input';
        }
      } else {
        // Normal digit
        input += value;
      }
    });
  }

  void clearInput() {
    setState(() {
      input = '';
    });
  }

  void submitInput() {
    if (isGameOver) return;

    final userAnswer = int.tryParse(input); // ✅ handles negative numbers
    if (userAnswer == null) return;

    if (userAnswer == correctAnswer) {
      SoundService().playCorrectSound();
      setState(() {
        showCorrectSplash = true;
        isGameOver = true;
      });
      _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            score++;
            input = '';
            showCorrectSplash = false;
          });
          generateQuestion();
        }
      });
      return;
    }

    // incorrect answer
    SoundService().playIncorrectSplashSound();
    setState(() {
      showIncorrectSplash = true;
      hearts--;
      isGameOver = true;
    });

    // 🔥 SAVE SCORE BEFORE SHOWING GAME OVER SCREEN
    unawaited(saveScore().catchError((e) {
      debugPrint('Error saving score on incorrect: $e');
    }));

    _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          showIncorrectSplash = false;
        });
        unawaited(_stopFaceProctor());
        showGameOverScreen(userAnswer);
      }
    });
  }

  void showLevelUpPage() {
    isGameOver = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpPopup(
        newLevel: level,
        message: 'Difficulty is increasing.\nKeep the momentum going!',
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            isGameOver = false;
            timerKey = UniqueKey();
          });
          unawaited(_startFaceProctor());
        },
      ),
    );
  }

  void showGameOverScreen(int incorrectAnswer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverPopup(
        incorrectAnswer: incorrectAnswer.toString(),
        correctAnswer: correctAnswer.toString(),
        heartsRemaining: hearts,
        onRetry: () {
          Navigator.pop(context);
          if (hearts <= 0) {
            setState(() {
              score = 0;
              level = 1;
              previousLevel = 1;
              hearts = gameDifficultyModeHearts(_selectedMode);
              input = '';
              timerKey = UniqueKey();
              isGameOver = false;
            });
            startGame(selectedMode!);
          } else {
            setState(() {
              input = '';
              timerKey = UniqueKey();
              isGameOver = false;
            });
            unawaited(_startFaceProctor());
            generateQuestion();
          }
        },
        onBack: () {
          Navigator.pop(context);
          unawaited(_stopFaceProctor());
          setState(() {
            selectedMode = null;
            pendingMode = null;
            score = 0;
            level = 1;
            previousLevel = 1;
            hearts = gameDifficultyModeHearts(_selectedMode);
          });
        },
      ),
    );
  }

  // 🔧 UPDATED saveScore with session-based logging to prevent duplicates
  Future<void> saveScore() async {
    if (_isSavingScore) return;
    _isSavingScore = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || selectedMode == null) return;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);

      // Use GameLogger which handles session-based logging
      await GameLogger.logGame(
        gameName: _gameNameFor(selectedMode!),
        score: score,
        difficulty: gameDifficultyModeLabel(_selectedMode),
        proctored: _runProctored,
      );

      final snapshot = await userRef.get();
      Map<String, dynamic> highscores = {};
      if (snapshot.exists && snapshot.data() != null) {
        highscores = Map<String, dynamic>.from(
          snapshot.data()?['math_highscores'] ?? {},
        );
      }

      final previousHigh = highscores[selectedMode!.name] ?? 0;
      if (score > previousHigh) {
        highscores[selectedMode!.name] = score;
        await userRef.set(
          {
            'math_highscores': highscores,
            'email': user.email,
          },
          SetOptions(merge: true),
        );

        // Update global leaderboard
        await updateLeaderboardEntry(
          gameName: _gameNameFor(selectedMode!),
          newScore: score,
          difficulty: gameDifficultyModeLabel(_selectedMode),
          proctored: _runProctored,
        );
      }
    } catch (e) {
      debugPrint('Error in saveScore (Math): $e');
    } finally {
      _isSavingScore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The screen drives every exit through _onAppBarBackPressed: it confirms, logs the
    // leave attempt, and saves the score. The Android hardware/gesture back
    // popped the route directly and skipped all three - no confirmation, no
    // score, and no proctoring record. `canPop: false` routes that gesture
    // into the same handler the on-screen arrow uses.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _onAppBarBackPressed();
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
              onPressed: _onAppBarBackPressed,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            title: Text(
              selectedMode == null
                  ? 'Math Quest'
                  : 'Math Quest: ${modeDisplayName(selectedMode!)}',
            ),
          ),
          body: Stack(
            children: [
              _buildBackground(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: selectedMode == null
                        ? (pendingMode != null
                            ? _buildModePreview()
                            : _buildModeSelection())
                        : _buildGameUI(),
                  ),
                ),
              ),
              if (showCorrectSplash)
                Positioned.fill(
                  child: CorrectSplash(
                    onComplete: () {},
                  ),
                ),
              if (showIncorrectSplash)
                Positioned.fill(
                  child: IncorrectSplash(
                    onComplete: () {},
                  ),
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
              if (_showLeaveWarning)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Warning',
                    message: _leaveWarningMessage,
                    isBusy: _processingLeaveAttempt,
                    okText: 'Leave',
                    backText: 'Stay',
                    onOk: _backFromLeaveWarning,
                    onBack: _restartFromLeaveWarning,
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
          baseOffset: Offset(-30, -24),
          drift: Offset(16, 11),
          size: 118,
          color: Color(0x2E9C27B0),
          borderColor: Color(0x4A2C1B47),
          initialRotation: -0.15,
          symbol: '+',
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
          symbol: '÷',
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
          symbol: '-',
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
          symbol: '×',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 24,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.centerLeft,
          baseOffset: Offset(-44, -10),
          drift: Offset(9, 8),
          size: 72,
          color: Color(0x249C27B0),
          borderColor: Color(0x382C1B47),
          symbol: '+',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 20,
          phase: 1.4,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.centerRight,
          baseOffset: Offset(44, 12),
          drift: Offset(9, 8),
          size: 72,
          color: Color(0x24F57C00),
          borderColor: Color(0x382C1B47),
          symbol: '÷',
          contentColor: Color(0xFF2C1B47),
          cornerRadius: 20,
          phase: 2.1,
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

  Widget _buildModeSelection() {
    const modes = MathMode.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width
                  .clamp(280.0, responsivePanelMaxWidth(width))
                  .toDouble(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _card(
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick Your Math Arena',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Solve equations fast, level up your brain, and beat the clock.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...modes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final mode = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Transform.rotate(
                        angle: index.isEven ? -0.01 : 0.01,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              SoundService().playButtonSoundNow();
                              setState(() => pendingMode = mode);
                            },
                            child: Text(modeDisplayName(mode)),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModePreview() {
    final mode = pendingMode!;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsivePanelMaxWidth(
            MediaQuery.sizeOf(context).width,
          ),
        ),
        child: _card(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                modeDisplayName(mode),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Solve as many problems as you can. Time limit per question: 10 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              const Text(
                'Difficulty',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              DifficultyModeSelector(
                selected: _selectedMode,
                accentColor: Theme.of(context).colorScheme.primary,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 4),
              Text(
                gameDifficultyModeDescription(_selectedMode),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        SoundService().playButtonSoundNow();
                        setState(() => pendingMode = null);
                      },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        SoundService().playButtonSoundNow();
                        startGame(mode);
                      },
                      child: const Text('Start'),
                    ),
                  ),
                ],
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
        _card(
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
              if (gameDifficultyModeHasTimer(_selectedMode))
                SizedBox(
                  width: 180,
                  child: GameTimer(
                    key: timerKey,
                    seconds: timeLimit,
                    isPaused: () => isGameOver,
                    onTimeUp: () {
                      setState(() {
                        isGameOver = true;
                      });
                      // 🔥 STOP CAMERA IMMEDIATELY ON TIMEOUT
                      unawaited(_stopFaceProctor());
                      // 🔧 Ensure saveScore is called with error handling
                      unawaited(saveScore().catchError((e) {
                        debugPrint('Error saving score on timeout: $e');
                      }));
                      showGameOverScreen(-1);
                    },
                    showBar: true,
                  ),
                )
              else
                const SizedBox(width: 180),
            ],
          ),
        ),
        const SizedBox(height: 14),
        HeartsDisplay(
          hearts: hearts,
          maxHearts: gameDifficultyModeHearts(_selectedMode),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.record_voice_over_rounded),
                  tooltip: 'Replay question voice',
                ),
              ),
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: NumberPad(
            input: input,
            isDisabled: isGameOver,
            onNumberTap: appendInput,
            onClear: clearInput,
            onSubmit: submitInput,
            showSignToggle: selectedMode == MathMode.subtract, 
          ),
        ),
      ],
    );
  }
}