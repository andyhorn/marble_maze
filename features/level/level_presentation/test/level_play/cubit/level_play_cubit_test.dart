import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

void main() {
  group('LevelPlayCubit', () {
    late _MockLevelsRepository repository;
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
    });

    blocTest<LevelPlayCubit, LevelPlayState>(
      'emits [loading, playing] when the level loads',
      setUp: () =>
          when(() => repository.getLevel('first_roll'))
              .thenAnswer((_) async => level),
      build: () => LevelPlayCubit(repository: repository),
      act: (cubit) => cubit.load('first_roll'),
      expect: () => [const LevelPlayLoading(), const LevelPlayPlaying(level)],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'emits [loading, error] for an unknown level id',
      setUp: () =>
          when(() => repository.getLevel('missing'))
              .thenThrow(const LevelNotFoundException('missing')),
      build: () => LevelPlayCubit(repository: repository),
      act: (cubit) => cubit.load('missing'),
      expect: () => [const LevelPlayLoading(), const LevelPlayError()],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'moves from playing to falling and back to playing',
      seed: () => const LevelPlayPlaying(level),
      build: () => LevelPlayCubit(repository: repository),
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
      build: () => LevelPlayCubit(repository: repository),
      act: (cubit) => cubit.marbleFell(),
      expect: () => <LevelPlayState>[],
    );

    blocTest<LevelPlayCubit, LevelPlayState>(
      'marbleRespawned() is ignored outside falling',
      seed: () => const LevelPlayPlaying(level),
      build: () => LevelPlayCubit(repository: repository),
      act: (cubit) => cubit.marbleRespawned(),
      expect: () => <LevelPlayState>[],
    );
  });
}
