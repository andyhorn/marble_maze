import 'package:progress_domain/src/level_record.dart';

/// Reads and saves the player's best times.
///
/// A storage failure never throws to callers: it is logged, and gameplay
/// continues without saving.
abstract interface class IProgressRepository {
  /// Returns every saved [LevelRecord], keyed by level id.
  ///
  /// Returns an empty map if no records are saved, or if reading fails.
  Future<Map<String, LevelRecord>> getRecords();

  /// Saves [time] as the best time for [levelId] if it beats (or is the
  /// first) recorded time, returning whether it was a new best.
  ///
  /// Returns false, without saving, if [time] does not beat the existing
  /// best, or if saving fails.
  Future<bool> submitTime(String levelId, Duration time);
}
