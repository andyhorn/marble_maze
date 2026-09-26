import 'package:meta/meta.dart';

/// A single row in the level select list: enough of a level's manifest
/// entry and saved progress to render it, without needing the full level.
@immutable
class LevelListEntry {
  /// Creates a level list entry.
  const new({
    required this.id,
    required this.title,
    required this.par,
    required this.bestTime,
  });

  /// The level's unique id.
  final String id;

  /// The level's display title.
  final String title;

  /// The level's par time, if it has one.
  final Duration? par;

  /// The player's saved best time for this level, if any.
  final Duration? bestTime;

  @override
  bool operator ==(Object other) =>
      other is LevelListEntry &&
      other.id == id &&
      other.title == title &&
      other.par == par &&
      other.bestTime == bestTime;

  @override
  int get hashCode => Object.hash(id, title, par, bestTime);

  @override
  String toString() => 'LevelListEntry(id: $id, title: $title)';
}
