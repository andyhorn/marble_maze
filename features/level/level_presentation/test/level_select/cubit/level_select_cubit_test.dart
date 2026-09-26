import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

void main() {
  group('LevelSelectCubit', () {
    late _MockLevelsRepository levelsRepository;
    late _MockProgressRepository progressRepository;

    setUp(() {
      levelsRepository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
    });

    LevelSelectCubit build() => LevelSelectCubit(
      levelsRepository: levelsRepository,
      progressRepository: progressRepository,
    );

    blocTest<LevelSelectCubit, LevelSelectState>(
      'emits [loading, loaded] with every level and its saved record',
      setUp: () {
        when(() => levelsRepository.getManifest()).thenAnswer(
          (_) async => const [
            LevelManifestEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
            ),
            LevelManifestEntry(id: 'second_roll', title: 'Second Roll'),
          ],
        );
        when(() => progressRepository.getRecords()).thenAnswer(
          (_) async => {
            'first_roll': const LevelRecord(
              levelId: 'first_roll',
              bestTime: Duration(seconds: 18),
            ),
          },
        );
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const LevelSelectLoading(),
        const LevelSelectLoaded([
          LevelListEntry(
            id: 'first_roll',
            title: 'First Roll',
            par: Duration(seconds: 20),
            bestTime: Duration(seconds: 18),
          ),
          LevelListEntry(
            id: 'second_roll',
            title: 'Second Roll',
            par: null,
            bestTime: null,
          ),
        ]),
      ],
    );

    blocTest<LevelSelectCubit, LevelSelectState>(
      'emits [loading, error] when the manifest fails to load',
      setUp: () {
        when(() => levelsRepository.getManifest()).thenThrow(Exception('boom'));
        when(() => progressRepository.getRecords()).thenAnswer((_) async => {});
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const LevelSelectLoading(), const LevelSelectError()],
    );
  });
}
