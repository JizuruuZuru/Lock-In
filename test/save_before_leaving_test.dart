import 'dart:async';

import 'package:benchmark/services/game_result_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a save that finishes is awaited normally', () async {
    var ran = false;
    await saveBeforeLeaving(() async => ran = true);
    expect(ran, isTrue);
  });

  test('a save that never completes lets the caller go at the deadline',
      () async {
    // The offline case, and the reason this helper exists. A Firestore write
    // future only completes once the server acknowledges it, so with no
    // connection it never completes at all - and every exit path that awaited
    // one stopped responding: the exit confirmation's Leave button, the back
    // arrow, and the security overlay's Leave.
    final stuck = Completer<void>();
    final watch = Stopwatch()..start();

    await saveBeforeLeaving(
      () => stuck.future,
      deadline: const Duration(milliseconds: 80),
    );
    watch.stop();

    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(70),
        reason: 'a healthy connection should still get its full deadline');
    expect(watch.elapsedMilliseconds, lessThan(3000),
        reason: 'but the caller is never held indefinitely');

    stuck.complete();
  });

  test('a save that throws is swallowed rather than escaping', () async {
    await saveBeforeLeaving(() async => throw StateError('offline'));
    // Reaching this line at all is the assertion: an exit path must not be
    // taken down by a failed write.
  });

  test('a synchronous throw is swallowed too', () async {
    await saveBeforeLeaving(() => throw StateError('bad call'));
  });

  test('a failure arriving after the deadline is not an unhandled error',
      () async {
    final stuck = Completer<void>();

    await saveBeforeLeaving(
      () => stuck.future,
      deadline: const Duration(milliseconds: 40),
    );

    // The write was given up on but is still in flight. A rules rejection on
    // reconnect must not surface as an unhandled asynchronous error long
    // after the screen has gone.
    stuck.completeError(StateError('rejected on reconnect'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
  });
}
