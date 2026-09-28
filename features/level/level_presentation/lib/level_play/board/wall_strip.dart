import 'dart:math' as math;

import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// One straight, visually continuous piece of wall, as the board renders it:
/// the wood grain runs along its length, and it samples its own region of
/// the shared wood texture.
///
/// A level stores walls only as horizontal [WallRun]s, so a vertical wall is
/// a column of separate one-cell runs. [wallStripsFor] merges those back into
/// a single vertical strip for rendering, so the wall reads as one piece of
/// wood rather than a stack of mismatched squares. Physics still uses the
/// original runs.
@immutable
class WallStrip {
  /// Creates a wall strip.
  const new({
    required this.cells,
    required this.center,
    required this.halfLength,
    required this.runsAlongZ,
    required this.grainOffset,
  });

  /// The grid cells the strip covers, in order along its length.
  final List<GridPoint> cells;

  /// The strip's world-space center on the floor (`y == 0`).
  final vm.Vector3 center;

  /// Half the strip's length along its long axis, in world units.
  final double halfLength;

  /// Whether the strip's long axis is world Z rather than world X.
  final bool runsAlongZ;

  /// Where in the shared wood texture this strip's grain starts, in UV
  /// units, so neighbouring strips don't show identical grain.
  final vm.Vector2 grainOffset;
}

/// The wall strips to render for [level]. See [WallStrip].
///
/// Runs longer than one cell stay as horizontal strips; one-cell runs that
/// stack in consecutive rows of the same column merge into one vertical
/// strip. A lone one-cell run becomes a one-cell vertical strip.
List<WallStrip> wallStripsFor(Level level) {
  final horizontal = level.walls
      .where((run) => run.length > 1)
      .map(
        (run) => _strip(
          firstColumn: run.startColumn,
          firstRow: run.row,
          length: run.length,
          runsAlongZ: false,
          level: level,
        ),
      );

  final singleRowsByColumn = <int, List<int>>{};
  for (final run in level.walls.where((run) => run.length == 1)) {
    singleRowsByColumn.putIfAbsent(run.startColumn, () => []).add(run.row);
  }

  final vertical = <WallStrip>[];
  for (final MapEntry(key: column, value: rows) in singleRowsByColumn.entries) {
    rows.sort();
    var firstRow = rows.first;
    var length = 1;
    for (final row in rows.skip(1)) {
      if (row == firstRow + length) {
        length++;
        continue;
      }
      vertical.add(
        _strip(
          firstColumn: column,
          firstRow: firstRow,
          length: length,
          runsAlongZ: true,
          level: level,
        ),
      );
      firstRow = row;
      length = 1;
    }
    vertical.add(
      _strip(
        firstColumn: column,
        firstRow: firstRow,
        length: length,
        runsAlongZ: true,
        level: level,
      ),
    );
  }

  return [...horizontal, ...vertical];
}

WallStrip _strip({
  required int firstColumn,
  required int firstRow,
  required int length,
  required bool runsAlongZ,
  required Level level,
}) {
  final lastColumn = runsAlongZ ? firstColumn : firstColumn + length - 1;
  final lastRow = runsAlongZ ? firstRow + length - 1 : firstRow;
  final center = gridCellCenter(
    (firstColumn + lastColumn) / 2,
    (firstRow + lastRow) / 2,
    width: level.width,
    height: level.height,
  );
  return WallStrip(
    cells: [
      for (var i = 0; i < length; i++)
        if (runsAlongZ)
          GridPoint(column: firstColumn, row: firstRow + i)
        else
          GridPoint(column: firstColumn + i, row: firstRow),
    ],
    center: center,
    halfLength: length / 2,
    runsAlongZ: runsAlongZ,
    grainOffset: _grainOffsetFor(
      column: firstColumn,
      row: firstRow,
      runsAlongZ: runsAlongZ,
    ),
  );
}

/// Seeded from the strip's position rather than drawn from a shared random
/// source, so a level's walls look the same every time it loads.
vm.Vector2 _grainOffsetFor({
  required int column,
  required int row,
  required bool runsAlongZ,
}) {
  final seed = (column * 1009 + row) * 2 + (runsAlongZ ? 1 : 0);
  final random = math.Random(seed);
  return vm.Vector2(random.nextDouble(), random.nextDouble());
}
