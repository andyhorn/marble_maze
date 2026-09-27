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
      repository.gravityController.add(const RawGravity(x: 0, y: 0, z: 9.81));
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
      repository.gravityController.add(const RawGravity(x: 0, y: 0, z: 9.81));
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
      repository.gravityController.add(const RawGravity(x: 0, y: 0, z: 9.81));
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

    testWidgets('visualTilt stays flat with the accelerometer and no drag', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(const RawGravity(x: -2, y: 0, z: 9.6));
      await initializing;
      controller.calibrate();

      expect(controller.visualTilt, Tilt.flat);
    });

    testWidgets('visualTilt follows a drag regardless of the accelerometer', (
      tester,
    ) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(const RawGravity(x: 0, y: 0, z: 9.81));
      await initializing;

      controller
        ..calibrate()
        ..dragStart(0, 0)
        ..dragUpdate(60, 0);

      expect(controller.visualTilt.x, greaterThan(0));
    });

    testWidgets('visualTilt eases toward flat after release, independent of '
        'the accelerometer-driven tilt', (tester) async {
      controller = LevelPlayInputController(repository: repository);
      final initializing = controller.initialize();
      await tester.pump();
      repository.gravityController.add(const RawGravity(x: 0, y: 0, z: 9.81));
      await initializing;

      controller
        ..calibrate()
        ..dragStart(0, 0)
        ..dragUpdate(60, 0)
        ..dragEnd();

      // The instant after release, before any easing has advanced, the
      // release tilt is still visible even though the accelerometer (now
      // driving physics via `tilt`) has settled to flat.
      expect(controller.tilt, Tilt.flat);
      expect(controller.visualTilt.x, greaterThan(0));

      controller.update(const Duration(seconds: 10));

      expect(controller.visualTilt, Tilt.flat);
    });
  });
}
