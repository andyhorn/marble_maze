import 'package:meta/meta.dart';

/// A player's best recorded time for a single level.
@immutable
class LevelRecord {
  /// Creates a level record.
  const new({required this.levelId, required this.bestTime});

  /// The id of the level this record is for.
  final String levelId;

  /// The best time recorded for this level.
  final Duration bestTime;

  @override
  bool operator ==(Object other) =>
      other is LevelRecord &&
      other.levelId == levelId &&
      other.bestTime == bestTime;

  @override
  int get hashCode => Object.hash(levelId, bestTime);

  @override
  String toString() => 'LevelRecord(levelId: $levelId, bestTime: $bestTime)';
}
