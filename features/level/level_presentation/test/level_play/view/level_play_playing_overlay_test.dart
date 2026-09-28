import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';

import '../../helpers/fake_stopwatch.dart';
import '../../helpers/pump_app.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

class _FakeTiltRepository implements ITiltRepository {
  bool isAvailableResult = true;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Stream<RawGravity> watchGravity() => Stream.value(RawGravity.flat);
}

void main() {
  group('LevelPlayPlayingOverlay', () {
    late LevelPlayCubit cubit;
    late LevelPlayInputController controller;

    setUp(() {
      final repository = _MockLevelsRepository();
      when(() => repository.getLevel('first_roll')).thenAnswer(
        (_) async => const Level(
          id: 'first_roll',
          title: 'First Roll',
          width: 3,
          height: 3,
          start: GridPoint(column: 0, row: 0),
          exit: GridPoint(column: 2, row: 2),
          holes: [],
          walls: [],
        ),
      );
      cubit = LevelPlayCubit(
        repository: repository,
        progressRepository: _MockProgressRepository(),
        stopwatchFactory: FakeStopwatch.new,
      );
    });

    testWidgets('shows the hint while touch-only input is active', (
      tester,
    ) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
        ),
      );

      expect(find.byType(LevelPlayTiltHint), findsOneWidget);
      controller.dispose();
    });

    testWidgets('hides the hint once the accelerometer is in use', (
      tester,
    ) async {
      final repository = _FakeTiltRepository();
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
        ),
      );

      expect(find.byType(LevelPlayTiltHint), findsNothing);
    });

    testWidgets('hides the hint once it is dismissed by a drag', (
      tester,
    ) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
        ),
      );
      controller.dragStart(0, 0);
      await tester.pump();

      expect(find.byType(LevelPlayTiltHint), findsNothing);
    });

    testWidgets('calls onPause when the pause button is tapped', (
      tester,
    ) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();
      var paused = false;

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () => paused = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.pause));

      expect(paused, isTrue);
      controller.dispose();
    });

    testWidgets('shows the bubble level even with touch-only input', (
      tester,
    ) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
        ),
      );

      expect(find.byType(BubbleLevelGauge), findsOneWidget);
      controller.dispose();
    });

    testWidgets('the bubble floats opposite the way the board rolls the '
        'marble', (tester) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();
      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
        ),
      );

      controller
        ..dragStart(0, 0)
        ..dragUpdate(60, 0);
      final applied = controller.tilt;
      await tester.pump();

      final gauge = tester.widget<BubbleLevelGauge>(
        find.byType(BubbleLevelGauge),
      );
      expect(applied.x, greaterThan(0));
      expect(gauge.xAngle, -applied.x);
      expect(gauge.fullScaleAngle, Tilt.maxTilt);
      controller.dispose();
    });

    testWidgets('hides the bubble level when showBubbleLevel is false', (
      tester,
    ) async {
      final repository = _FakeTiltRepository()..isAvailableResult = false;
      controller = LevelPlayInputController(repository: repository);
      await controller.initialize();

      await tester.pumpApp(
        LevelPlayPlayingOverlay(
          cubit: cubit,
          title: 'First Roll',
          controller: controller,
          onPause: () {},
          showBubbleLevel: false,
        ),
      );

      expect(find.byType(BubbleLevelGauge), findsNothing);
      controller.dispose();
    });
  });
}
