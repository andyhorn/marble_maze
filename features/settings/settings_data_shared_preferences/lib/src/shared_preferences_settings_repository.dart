import 'dart:developer';

import 'package:settings_domain/settings_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCalibrateTiltKey = 'settings.calibrate_tilt';

/// An [ISettingsRepository] backed by `shared_preferences`.
///
/// A storage failure is logged and never thrown: reads fall back to the
/// default and writes are dropped.
class SharedPreferencesSettingsRepository implements ISettingsRepository {
  /// Creates a settings repository.
  ///
  /// [preferences] builds the [SharedPreferences] instance this repository
  /// reads and writes through, defaulting to [SharedPreferences.getInstance].
  new({
    Future<SharedPreferences> Function() preferences =
        SharedPreferences.getInstance,
  }) : // External name preferences is clearer at call sites than the
       // private field it initializes.
       // ignore: prefer_initializing_formals
       _preferences = preferences;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<bool> getCalibrateTilt() async {
    try {
      final prefs = await _preferences();
      return prefs.getBool(_kCalibrateTiltKey) ?? true;
    } on Exception catch (error, stackTrace) {
      log('Failed to read settings', error: error, stackTrace: stackTrace);
      return true;
    }
  }

  @override
  Future<void> setCalibrateTilt({required bool value}) async {
    try {
      final prefs = await _preferences();
      await prefs.setBool(_kCalibrateTiltKey, value);
    } on Exception catch (error, stackTrace) {
      log('Failed to save settings', error: error, stackTrace: stackTrace);
    }
  }
}
