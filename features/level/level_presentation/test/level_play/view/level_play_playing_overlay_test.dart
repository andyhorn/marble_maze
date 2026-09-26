import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilt_domain/tilt_domain.dart';

import '../../helpers/fake_stopwatch.dart';
import '../../helpers/pump_app.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _FakeTiltRepository implements ITiltRepository {
  bool isAvailableResult = true;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Stream<RawGravity> watchGravity() =>
      Stream.value(const RawGravity(x: 0, y: 0, z: 9.81));
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
        ),
      );
      controller.dragStart(0, 0);
      await tester.pump();

      expect(find.byType(LevelPlayTiltHint), findsNothing);
    });
  });
}
