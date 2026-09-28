import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:level_presentation/settings/cubit/settings_state.dart';
import 'package:settings_domain/settings_domain.dart';

/// Loads the player's settings from an [ISettingsRepository] and saves
/// changes to them.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a settings cubit that reads and writes [settingsRepository].
  new({required ISettingsRepository settingsRepository})
    : // External name settingsRepository is clearer at call sites than the
      // private field it initializes.
      // ignore: prefer_initializing_formals
      _settingsRepository = settingsRepository,
      super(const SettingsState());

  final ISettingsRepository _settingsRepository;

  /// Loads the saved settings.
  Future<void> load() async {
    final calibrateTilt = await _settingsRepository.getCalibrateTilt();
    emit(SettingsState(calibrateTilt: calibrateTilt));
  }

  /// Sets and saves whether tilt calibrates to the held angle.
  Future<void> setCalibrateTilt({required bool value}) async {
    emit(SettingsState(calibrateTilt: value));
    await _settingsRepository.setCalibrateTilt(value: value);
  }
}
