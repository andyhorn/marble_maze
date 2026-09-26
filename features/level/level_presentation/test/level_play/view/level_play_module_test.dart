import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

import '../../helpers/pump_app.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

/// Reports no accelerometer, so tests exercise the touch-only fallback
/// without waiting on the real 500 ms probe window.
class _FakeTiltRepository implements ITiltRepository {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<RawGravity> watchGravity() => const Stream.empty();
}

class _FakeMarbleSimulation implements IMarbleSimulation {
  int respawnCount = 0;

  @override
  void load(Level level) {}

  @override
  void step(Tilt tilt, Duration elapsed) {}

  @override
  void respawn() => respawnCount++;

  @override
  MarbleState get marble => MarbleState(
    position: Vector3.zero(),
    rotation: Quaternion.identity(),
    velocity: Vector3.zero(),
    isActive: true,
  );

  @override
  Stream<SimulationEvent> get events => const Stream.empty();

  @override
  void dispose() {}
}

Widget _placeholderBoardBuilder({
  required Level level,
  required IMarbleSimulation simulation,
  required bool isSimulationActive,
  required LevelPlayInputController controller,
  required VoidCallback onMarbleFell,
  required VoidCallback onMarbleRespawned,
  required VoidCallback onReachedExit,
}) => const Placeholder();

const _level = Level(
  id: 'first_roll',
  title: 'First Roll',
  par: Duration(seconds: 20),
  width: 3,
  height: 3,
  start: GridPoint(column: 0, row: 0),
  exit: GridPoint(column: 2, row: 2),
  holes: [],
  walls: [],
);

void main() {
  group('LevelPlayModule', () {
    late _MockLevelsRepository repository;
    late _MockProgressRepository progressRepository;
    late _FakeMarbleSimulation simulation;
    late String? nextLevelId;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    setUp(() {
      repository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
      simulation = _FakeMarbleSimulation();
      nextLevelId = null;
      when(() => repository.getManifest()).thenAnswer((_) async => []);
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});
      when(() => progressRepository.submitTime(any(), any()))
          .thenAnswer((_) async => true);
    });

    Widget buildSubject() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ILevelsRepository>.value(value: repository),
          RepositoryProvider<IProgressRepository>.value(
            value: progressRepository,
          ),
          RepositoryProvider<ITiltRepository>.value(
            value: _FakeTiltRepository(),
          ),
        ],
        child: LevelPlayModule(
          levelId: 'first_roll',
          simulationFactory: () => simulation,
          onExitToLevels: () {},
          onNextLevel: (id) => nextLevelId = id,
          boardBuilder: _placeholderBoardBuilder,
        ),
      );
    }

    testWidgets('shows a loading view while the level loads', (tester) async {
      // A never-completing future, rather than Future.delayed, so no timer
      // is left pending when the test tears down.
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) => Completer<Level>().future);

      await tester.pumpApp(buildSubject());

      expect(find.byType(LevelPlayLoadingView), findsOneWidget);
    });

    testWidgets('shows the ready overlay once the level loads', (tester) async {
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) async => _level);

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LevelPlayReadyOverlay), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('shows an error view for an unknown level', (tester) async {
      when(() => repository.getLevel('first_roll'))
          .thenThrow(const LevelNotFoundException('first_roll'));

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LevelPlayErrorView), findsOneWidget);
    });

    group('once the marble reaches the exit', () {
      setUp(() {
        when(() => repository.getLevel('first_roll'))
            .thenAnswer((_) async => _level);
      });

      Future<void> reachExit(WidgetTester tester) async {
        await tester.pumpApp(buildSubject());
        await tester.pumpAndSettle();
        tester
            .element(find.byType(LevelPlayReadyOverlay))
            .read<LevelPlayCubit>()
          ..start()
          ..marbleReachedExit();
        await tester.pumpAndSettle();
      }

      testWidgets('hides Next on the last level', (tester) async {
        await reachExit(tester);

        expect(find.byType(LevelPlayWonOverlay), findsOneWidget);
        expect(find.text('Next'), findsNothing);
      });

      testWidgets('retry respawns the marble and returns to ready', (
        tester,
      ) async {
        await reachExit(tester);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(simulation.respawnCount, 1);
        expect(find.byType(LevelPlayReadyOverlay), findsOneWidget);
      });

      testWidgets('Next calls onNextLevel with the next level id', (
        tester,
      ) async {
        when(() => repository.getManifest()).thenAnswer(
          (_) async => const [
            LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
            LevelManifestEntry(id: 'second_roll', title: 'Second Roll'),
          ],
        );
        await reachExit(tester);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(nextLevelId, 'second_roll');
      });
    });
  });
}
