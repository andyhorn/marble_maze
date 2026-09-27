import 'dart:collection';
import 'dart:io';

import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:test/test.dart';

/// Reads a bundled level asset straight off disk, stripping the
/// `packages/level_data/` prefix the app resolves through `rootBundle`.
///
/// `dart test` runs from this package's root, so the stripped path
/// resolves directly.
Future<String> _diskLoader(String path) {
  final relative = path.replaceFirst('packages/level_data/', '');
  return File(relative).readAsString();
}

/// Whether [level]'s exit is reachable from its start over 4-connected
/// floor/start/exit cells, without ever entering a hole cell.
bool _isCompletable(Level level) {
  final wallCells = <GridPoint>{
    for (final wall in level.walls)
      for (var i = 0; i < wall.length; i++)
        GridPoint(column: wall.startColumn + i, row: wall.row),
  };
  final holeCells = level.holes.toSet();

  bool isOpenFloor(GridPoint point) =>
      point.column >= 0 &&
      point.column < level.width &&
      point.row >= 0 &&
      point.row < level.height &&
      !wallCells.contains(point) &&
      !holeCells.contains(point);

  final visited = {level.start};
  final queue = Queue<GridPoint>()..add(level.start);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == level.exit) return true;

    final neighbors = [
      GridPoint(column: current.column + 1, row: current.row),
      GridPoint(column: current.column - 1, row: current.row),
      GridPoint(column: current.column, row: current.row + 1),
      GridPoint(column: current.column, row: current.row - 1),
    ];
    for (final neighbor in neighbors) {
      if (visited.contains(neighbor) || !isOpenFloor(neighbor)) continue;
      visited.add(neighbor);
      queue.add(neighbor);
    }
  }
  return false;
}

const _unreachableExitText = '''
# title: Blocked
#####
#S#.#
#O#.#
#...#
##.E#
#####''';

void main() {
  test('every bundled level parses without error', () async {
    const dataSource = AssetLevelDataSource(loader: _diskLoader);
    final repository = LevelsRepository(dataSource: dataSource);

    final manifest = await repository.getManifest();

    expect(manifest, isNotEmpty);
    for (final entry in manifest) {
      final level = await repository.getLevel(entry.id);
      expect(level.id, entry.id);
    }
  });

  test('every bundled level is completable', () async {
    const dataSource = AssetLevelDataSource(loader: _diskLoader);
    final repository = LevelsRepository(dataSource: dataSource);

    final manifest = await repository.getManifest();

    expect(manifest, isNotEmpty);
    for (final entry in manifest) {
      final level = await repository.getLevel(entry.id);
      expect(
        _isCompletable(level),
        isTrue,
        reason:
            "level '${entry.id}' has no floor path from start to exit "
            'that avoids every hole',
      );
    }
  });

  test('_isCompletable rejects a level whose only route to the exit crosses a '
      'hole', () {
    final level = LevelTextParser().parse(
      _unreachableExitText,
      fileName: 'blocked.txt',
    );

    expect(_isCompletable(level), isFalse);
  });
}
