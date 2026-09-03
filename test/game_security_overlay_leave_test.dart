import 'dart:async';

import 'package:benchmark/services/face_proctor_contract.dart';
import 'package:benchmark/widgets/game_security_overlay.dart';
import 'package:benchmark/widgets/leave_warning_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A proctor that starts cleanly and lets the test fire a violation, which is
/// what raises the warning overlay carrying the Leave button.
class _ViolatingProctor implements FaceProctorService {
  FaceViolationCallback? _onViolation;

  @override
  bool get isRunning => _onViolation != null;

  @override
  Future<FaceProctorStartStatus> start({
    required FaceViolationCallback onViolation,
    Duration absenceThreshold = const Duration(seconds: 3),
  }) async {
    _onViolation = onViolation;
    return FaceProctorStartStatus.started;
  }

  @override
  Future<void> stop() async => _onViolation = null;

  void fireViolation() => _onViolation?.call(
        const FaceViolationEvent(
          reason: FaceViolationReason.noFaceDetected,
          secondsWithoutValidFace: 3,
        ),
      );
}

void main() {
  late _ViolatingProctor proctor;
  late List<bool> lockChanges;
  late int onLeaveCalls;

  setUp(() {
    proctor = _ViolatingProctor();
    lockChanges = <bool>[];
    onLeaveCalls = 0;
  });

  /// A stand-in for a real game screen, reproducing the two things about them
  /// that broke the Leave button: a `PopScope(canPop: false)` guarding the
  /// route, and an `onLeave` that saves the score without navigating.
  Widget gameScreen({Future<void> Function()? onLeave}) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // The real screens route the gesture into their own confirm-and-save
        // handler, which does nothing while a warning overlay is up.
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('GAME SCREEN')),
            GameSecurityOverlay(
              gameName: 'Test Game',
              isActive: true,
              faceProctor: proctor,
              onLockChanged: lockChanges.add,
              onLeave: () async {
                onLeaveCalls++;
                if (onLeave != null) await onLeave();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openGameAndViolate(
    WidgetTester tester, {
    Future<void> Function()? onLeave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => gameScreen(onLeave: onLeave),
                  ),
                ),
                child: const Text('OPEN GAME'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN GAME'));
    await tester.pumpAndSettle();
    expect(find.text('GAME SCREEN'), findsOneWidget);

    proctor.fireViolation();
    await tester.pumpAndSettle();
    expect(find.byType(LeaveWarningOverlay), findsOneWidget);
  }

  testWidgets('Leave actually leaves the game screen', (tester) async {
    // The regression. `onLeave` used to make the *caller* responsible for
    // navigating, and eight of the ten screens supplying one only saved the
    // score - so Leave dismissed the warning and dropped the player straight
    // back into the game they had just asked to leave.
    await openGameAndViolate(tester);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(onLeaveCalls, 1, reason: 'the screen still gets to save its score');
    expect(find.text('GAME SCREEN'), findsNothing,
        reason: 'Leave has to actually leave');
    expect(find.text('OPEN GAME'), findsOneWidget,
        reason: 'and land back on the screen underneath, not somewhere else');
  });

  testWidgets('Leave is not swallowed by the screen\'s PopScope',
      (tester) async {
    // The second half of the same bug: the overlay's fallback used `maybePop`,
    // which `PopScope(canPop: false)` intercepts. It popped nothing and handed
    // control back to the screen's own back handler instead.
    await openGameAndViolate(tester);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveWarningOverlay), findsNothing);
    expect(find.text('OPEN GAME'), findsOneWidget);
  });

  testWidgets('leaving does not unlock the game on the way out',
      (tester) async {
    // `onLockChanged(false)` clears `isGameOver` and hands most screens a
    // fresh timer key, restarting the countdown for however long the save
    // takes. Nothing should resume a round the player is walking out of.
    await openGameAndViolate(tester);
    expect(lockChanges, [true], reason: 'the violation locks the screen');

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(lockChanges, [true],
        reason: 'and it is never unlocked again before the screen goes');
  });

  testWidgets('Leave still leaves when the save never finishes',
      (tester) async {
    // The offline case. A Firestore write future only completes when the
    // server acknowledges it, so `onLeave`'s save never returns on a device
    // with no connection - and Leave used to wait on it forever.
    final stuck = Completer<void>();
    await openGameAndViolate(tester, onLeave: () => stuck.future);

    await tester.tap(find.text('Leave'));
    await tester.pump();
    expect(find.text('GAME SCREEN'), findsOneWidget,
        reason: 'a healthy connection still gets its deadline to save');

    // Past `saveBeforeLeaving`'s deadline.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('GAME SCREEN'), findsNothing,
        reason: 'a save that never lands must not trap the player');
    expect(find.text('OPEN GAME'), findsOneWidget);

    stuck.complete();
  });

  testWidgets('Stay keeps the player in the game and unlocks it',
      (tester) async {
    // The other half of the same dialog, so a fix to Leave cannot quietly
    // break Stay.
    await openGameAndViolate(tester);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('GAME SCREEN'), findsOneWidget);
    expect(find.byType(LeaveWarningOverlay), findsNothing);
    expect(onLeaveCalls, 0);
    expect(lockChanges, [true, false]);
  });
}
