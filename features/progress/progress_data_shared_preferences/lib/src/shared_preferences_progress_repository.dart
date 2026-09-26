import 'dart:developer';

import 'package:progress_domain/progress_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shared_preferences key prefix a level's best time is stored under.
const _kBestTimeKeyPrefix = 'best_time.';

/// An [IProgressRepository] backed by `shared_preferences`, storing each
/// level's best time as milliseconds under `best_time.<levelId>`.
///
/// A storage failure is logged and never thrown: [getRecords] returns
/// whatever it can read (or an empty map), and [submitTime] returns false
/// without saving.
class SharedPreferencesProgressRepository implements IProgressRepository {
  /// Creates a progress repository.
  ///
  /// [preferences] builds the [SharedPreferences] instance this repository
  /// reads and writes through, defaulting to [SharedPreferences.getInstance].
  /// Tests inject a fake so a failure to obtain an instance is exercised
  /// too, since it must never throw to callers.
  new({
    Future<SharedPreferences> Function() preferences =
        SharedPreferences.getInstance,
  }) : // External name preferences is clearer at call sites than the
       // private field it initializes.
       // ignore: prefer_initializing_formals
       _preferences = preferences;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<Map<String, LevelRecord>> getRecords() async {
    try {
      final prefs = await _preferences();
      final records = <String, LevelRecord>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_kBestTimeKeyPrefix)) continue;
        final milliseconds = prefs.getInt(key);
        if (milliseconds == null) continue;
        final levelId = key.substring(_kBestTimeKeyPrefix.length);
        records[levelId] = LevelRecord(
          levelId: levelId,
          bestTime: Duration(milliseconds: milliseconds),
        );
      }
      return records;
    } on Exception catch (error, stackTrace) {
      log(
        'Failed to read progress records',
        error: error,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  @override
  Future<bool> submitTime(String levelId, Duration time) async {
    try {
      final prefs = await _preferences();
      final key = '$_kBestTimeKeyPrefix$levelId';
      final existing = prefs.getInt(key);
      if (existing != null && existing <= time.inMilliseconds) return false;

      return await prefs.setInt(key, time.inMilliseconds);
    } on Exception catch (error, stackTrace) {
      log('Failed to save progress', error: error, stackTrace: stackTrace);
      return false;
    }
  }
}
