import 'package:level_domain/src/grid_point.dart';
import 'package:level_domain/src/wall_run.dart';
import 'package:meta/meta.dart';

/// A single playable maze level: its grid dimensions, start and exit cells,
/// holes, and walls.
@immutable
class Level {
  /// Creates a level.
  const new({
    required this.id,
    required this.title,
    required this.width,
    required this.height,
    required this.start,
    required this.exit,
    required this.holes,
    required this.walls,
    this.par,
  });

  /// The level's unique id (the level file's name without its extension).
  final String id;

  /// The level's display title.
  final String title;

  /// An optional par time for the level.
  final Duration? par;

  /// The grid width, in cells.
  final int width;

  /// The grid height, in cells.
  final int height;

  /// The marble's starting cell.
  final GridPoint start;

  /// The exit cell.
  final GridPoint exit;

  /// The cells that contain a hole.
  final List<GridPoint> holes;

  /// The merged horizontal wall runs.
  final List<WallRun> walls;

  @override
  bool operator ==(Object other) {
    if (other is! Level) return false;
    return other.id == id &&
        other.title == title &&
        other.par == par &&
        other.width == width &&
        other.height == height &&
        other.start == start &&
        other.exit == exit &&
        _listEquals(other.holes, holes) &&
        _listEquals(other.walls, walls);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    par,
    width,
    height,
    start,
    exit,
    Object.hashAll(holes),
    Object.hashAll(walls),
  );

  @override
  String toString() => 'Level(id: $id, title: $title)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
