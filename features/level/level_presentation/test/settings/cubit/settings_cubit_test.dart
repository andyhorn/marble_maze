import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_domain/settings_domain.dart';

class _MockSettingsRepository extends Mock implements ISettingsRepository;

void main() {
  group('SettingsCubit', () {
    late _MockSettingsRepository settingsRepository;

    setUp(() {
      settingsRepository = _MockSettingsRepository();
      when(
        () => settingsRepository.setCalibrateTilt(value: any(named: 'value')),
      ).thenAnswer((_) async {});
      when(
        () => settingsRepository.setShowBubbleLevel(value: any(named: 'value')),
      ).thenAnswer((_) async {});
    });

    SettingsCubit buildCubit() =>
        SettingsCubit(settingsRepository: settingsRepository);

    test('calibrates tilt before anything loads', () {
      expect(buildCubit().state, const SettingsState());
    });

    blocTest<SettingsCubit, SettingsState>(
      'load emits the saved setting',
      setUp: () {
        when(() => settingsRepository.getCalibrateTilt())
            .thenAnswer((_) async => false);
        when(() => settingsRepository.getShowBubbleLevel())
            .thenAnswer((_) async => false);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const SettingsState(calibrateTilt: false, showBubbleLevel: false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setCalibrateTilt emits and saves the new value',
      build: buildCubit,
      act: (cubit) => cubit.setCalibrateTilt(value: false),
      expect: () => [const SettingsState(calibrateTilt: false)],
      verify: (_) =>
          verify(() => settingsRepository.setCalibrateTilt(value: false))
              .called(1),
    );

    blocTest<SettingsCubit, SettingsState>(
      'setShowBubbleLevel emits and saves the new value, keeping the rest',
      build: buildCubit,
      seed: () => const SettingsState(calibrateTilt: false),
      act: (cubit) => cubit.setShowBubbleLevel(value: false),
      expect: () => [
        const SettingsState(calibrateTilt: false, showBubbleLevel: false),
      ],
      verify: (_) =>
          verify(() => settingsRepository.setShowBubbleLevel(value: false))
              .called(1),
    );
  });
}
