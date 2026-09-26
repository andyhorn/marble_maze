import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';

import '../../helpers/fake_stopwatch.dart';
import '../../helpers/pump_app.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

void main() {
  group('LevelPlayHud', () {
    late _MockLevelsRepository repository;
    late _MockProgressRepository progressRepository;
    late FakeStopwatch stopwatch;
    const level = Level(
      id: 'first_roll',
      title: 'First Roll',
      width: 3,
      height: 3,
      start: GridPoint(column: 0, row: 0),
      exit: GridPoint(column: 2, row: 2),
      holes: [],
      walls: [],
    );

    setUp(() {
      repository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
      stopwatch = FakeStopwatch();
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) async => level);
      when(() => repository.getManifest()).thenAnswer((_) async => []);
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});
    });

    testWidgets('shows the level title and formatted elapsed time', (
      tester,
    ) async {
      final cubit = LevelPlayCubit(
        repository: repository,
        progressRepository: progressRepository,
        stopwatchFactory: () => stopwatch,
      );
      await cubit.load('first_roll');
      cubit.start();
      stopwatch.elapsed = const Duration(
        minutes: 1,
        seconds: 5,
        milliseconds: 320,
      );

      await tester.pumpApp(LevelPlayHud(cubit: cubit, title: level.title));
      await tester.pump();

      expect(find.text('First Roll'), findsOneWidget);
      expect(find.text('1:05.32'), findsOneWidget);
    });
  });
}
