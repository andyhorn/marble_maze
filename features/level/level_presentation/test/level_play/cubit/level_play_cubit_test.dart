import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';

import '../../helpers/fake_stopwatch.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

void main() {
  group('LevelPlayCubit', () {
    late _MockLevelsRepository repository;
    late _MockProgressRepository progressRepository;
    late FakeStopwatch stopwatch;
    const level = Level(
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
    const secondLevelEntry = LevelManifestEntry(
      id: 'second_roll',
      title: 'Second Roll',
    );

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    setUp(() {
      repository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
      stopwatch = FakeStopwatch();
      when(() => repository.getManifest()).thenAnswer(
        (_) async => [
          const LevelManifestEntry(
            id: 'first_roll',
            title: 'First Roll',
            par: Duration(seconds: 20),
          ),
          secondLevelEntry,
        ],
      );
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});
      when(() => progressRepository.submitTime(any(), any()))
          .thenAnswer((_) async => true);
    });

    LevelPlayCubit build() => LevelPlayCubit(
      repository: repository,
      progressRepository: progressRepository,
      stopwatchFactory: () => stopwatch,
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'emits [loading, ready] when the level loads',
      setUp: () =>
          when(() => repository.getLevel('first_roll'))
              .thenAnswer((_) async => level),
      build: build,
      act: (cubit) => cubit.load('first_roll'),
      expect: () => [const LevelPlayLoading(), const LevelPlayReady(level)],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'emits [loading, error] for an unknown level id',
      setUp: () =>
          when(() => repository.getLevel('missing'))
              .thenThrow(const LevelNotFoundException('missing')),
      build: build,
      act: (cubit) => cubit.load('missing'),
      expect: () => [const LevelPlayLoading(), const LevelPlayError()],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'start() moves from ready to playing and starts the timer',
      seed: () => const LevelPlayReady(level),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [const LevelPlayPlaying(level)],
      verify: (_) => expect(stopwatch.isRunning, isTrue),
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'start() is ignored outside ready',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'moves from playing to falling and back to playing',
      seed: () => const LevelPlayPlaying(level),
      build: build,
      act: (cubit) {
        cubit
          ..marbleFell()
          ..marbleRespawned();
      },
      expect: () => [
        const LevelPlayFalling(level),
        const LevelPlayPlaying(level),
      ],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleFell() is ignored outside playing',
      build: build,
      act: (cubit) => cubit.marbleFell(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleRespawned() is ignored outside falling',
      seed: () => const LevelPlayPlaying(level),
      build: build,
      act: (cubit) => cubit.marbleRespawned(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleReachedExit() moves from playing to won and stops the timer',
      seed: () => const LevelPlayReady(level),
      build: build,
      act: (cubit) {
        cubit.start();
        stopwatch.elapsed = const Duration(seconds: 12);
        cubit.marbleReachedExit();
      },
      expect: () => [
        const LevelPlayPlaying(level),
        const LevelPlayWon(
          level: level,
          time: Duration(seconds: 12),
          par: Duration(seconds: 20),
          bestTime: Duration(seconds: 12),
          isNewBest: true,
          nextLevelId: null,
        ),
      ],
      verify: (_) => expect(stopwatch.isRunning, isFalse),
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleReachedExit() reports the saved best, a slower run, and the '
      'next level, after load() has fetched them',
      setUp: () {
        when(() => repository.getLevel('first_roll'))
            .thenAnswer((_) async => level);
        when(() => progressRepository.getRecords()).thenAnswer(
          (_) async => {
            'first_roll': const LevelRecord(
              levelId: 'first_roll',
              bestTime: Duration(seconds: 10),
            ),
          },
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load('first_roll');
        cubit.start();
        stopwatch.elapsed = const Duration(seconds: 12);
        cubit.marbleReachedExit();
      },
      expect: () => [
        const LevelPlayLoading(),
        const LevelPlayReady(level),
        const LevelPlayPlaying(level),
        const LevelPlayWon(
          level: level,
          time: Duration(seconds: 12),
          par: Duration(seconds: 20),
          bestTime: Duration(seconds: 10),
          isNewBest: false,
          nextLevelId: 'second_roll',
        ),
      ],
      verify: (_) => verify(
        () => progressRepository.submitTime(
          'first_roll',
          const Duration(seconds: 12),
        ),
      ).called(1),
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'retry() moves from won back to ready',
      seed: () => const LevelPlayWon(
        level: level,
        time: Duration(seconds: 12),
        par: Duration(seconds: 20),
        bestTime: Duration(seconds: 12),
        isNewBest: true,
        nextLevelId: null,
      ),
      build: build,
      act: (cubit) => cubit.retry(),
      expect: () => [const LevelPlayReady(level)],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'retry() is ignored outside won',
      seed: () => const LevelPlayReady(level),
      build: build,
      act: (cubit) => cubit.retry(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleReachedExit() is ignored while ready',
      seed: () => const LevelPlayReady(level),
      build: build,
      act: (cubit) => cubit.marbleReachedExit(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleReachedExit() is ignored while falling',
      seed: () => const LevelPlayFalling(level),
      build: build,
      act: (cubit) => cubit.marbleReachedExit(),
      expect: () => <LevelPlayState>[],
    );

    test('elapsed is zero before start() is called', () {
      final cubit = build();
      expect(cubit.elapsed, Duration.zero);
    });

    test('elapsed reflects the injected stopwatch once started', () async {
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) async => level);
      final cubit = build();
      await cubit.load('first_roll');
      cubit.start();
      stopwatch.elapsed = const Duration(seconds: 7);

      expect(cubit.elapsed, const Duration(seconds: 7));
    });
  });
}
