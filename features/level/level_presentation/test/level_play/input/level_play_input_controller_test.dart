import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// A controllable [ITiltRepository]: tests drive [isAvailableResult] and
/// emit readings through [gravityController] on their own schedule.
class _FakeTiltRepository implements ITiltRepository {
  bool isAvailableResult = true;
  final gravityController = StreamController<RawGravity>.broadcast();

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Stream<RawGravity> watchGravity() => gravityController.stream;
}

void main() {
  group('LevelPlayInputController', () {
    late _FakeTiltRepository repository;
    late LevelPlayInputController controller;

    setUp(() {
      repository = _FakeTiltRepository();
    });

    tearDown(() {
      unawaited(repository.gravityController.close());
    });

    testWidgets('uses the accelerometer once a reading arrives', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);

      final initializing = controller.initialize();
      // Lets the pending isAvailable() await resolve and the gravity stream
      // subscription attach, so the reading below isn't dropped by the
      // broadcast stream having no listener yet.
      await tester.pump();
      repository.gravityController.add(RawGravity.flat);
      await initializing;

      expect(controller.useAccelerometer, isTrue);
      expect(controller.showHint, isFalse);
      controller.dispose();
    });

    testWidgets('falls back to touch when isAvailable is false', (
      tester,
    ) async {
      repository.isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);

      await controller.initialize();

      expect(controller.useAccelerometer, isFalse);
      expect(controller.showHint, isTrue);
      // Cancels the hint timer the fallback above scheduled: this test's
      // body must leave no pending timer when it returns, since flutter_test
      // checks for leaks before this group's tearDown runs.
      controller.dispose();
    });

    testWidgets('falls back to touch when no reading arrives in time', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);

      final initializing = controller.initialize();
      await tester.pump(const Duration(milliseconds: 500));
      await initializing;

      expect(controller.useAccelerometer, isFalse);
      expect(controller.showHint, isTrue);
      controller.dispose();
    });

    testWidgets('the hint dismisses itself after hintDuration', (tester) async {
      repository.isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();
      expect(controller.showHint, isTrue);

      await tester.pump(const Duration(seconds: 4));

      expect(controller.showHint, isFalse);
      controller.dispose();
    });

    testWidgets('a drag dismisses the hint immediately', (tester) async {
      repository.isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      controller.dragStart(0, 0);

      expect(controller.showHint, isFalse);
      controller.dispose();
    });

    testWidgets('touch overrides the accelerometer while dragging', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(RawGravity.flat);
      await initializing;

      controller
        ..calibrate()
        ..dragStart(0, 0)
        ..dragUpdate(60, 0);

      expect(controller.tilt.x, greaterThan(0));
    });

    testWidgets('the accelerometer resumes once the finger lifts', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(RawGravity.flat);
      await initializing;

      controller
        ..calibrate()
        ..dragStart(0, 0)
        ..dragUpdate(60, 0)
        ..dragEnd();

      expect(controller.tilt, Tilt.flat);
    });

    testWidgets('calibrate uses the latest gravity reading', (tester) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(const RawGravity(x: -2, y: 0, z: 9.6));
      await initializing;

      controller.calibrate();

      expect(controller.tilt, Tilt.flat);
    });

    testWidgets('calibrate without toHeldAngle measures tilt from flat', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(const RawGravity(x: -2, y: 0, z: 9.6));
      await initializing;

      controller.calibrate(toHeldAngle: false);

      expect(controller.tilt.x, greaterThan(0));
      expect(controller.tilt.y, 0);
    });

    testWidgets('lastTilt is flat until tilt is read, then follows it', (
      tester,
    ) async {
      repository.isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();
      expect(controller.lastTilt, Tilt.flat);

      controller
        ..dragStart(0, 0)
        ..dragUpdate(60, 0);
      final applied = controller.tilt;

      expect(controller.lastTilt, applied);
      controller.dispose();
    });
  });
}
