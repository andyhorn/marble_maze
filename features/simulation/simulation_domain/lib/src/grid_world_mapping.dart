import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';

/// Maps a grid [column] / [row] to its center in world space, for a board
/// [width] by [height] cells.
///
/// 1 cell = 1 world unit; the board is centered on the origin in the X/Z
/// plane, with Y up. Row 0 (the far edge of the grid) maps to the most
/// positive Z; column 0 maps to the most negative X. [column] and [row] may
/// be fractional, to place geometry spanning more than one cell.
Vector3 gridCellCenter(
  num column,
  num row, {
  required int width,
  required int height,
}) {
  final x = column - (width - 1) / 2;
  final z = (height - 1) / 2 - row;
  return Vector3(x, 0, z);
}

/// Maps [point] to its cell center in world space. See [gridCellCenter].
Vector3 gridPointCenter(
  GridPoint point, {
  required int width,
  required int height,
}) => gridCellCenter(point.column, point.row, width: width, height: height);

/// The world-space center and half-length of a merged [WallRun] collider,
/// for a board of some width and height, in cells.
@immutable
class WallRunPlacement {
  /// Creates a wall run placement.
  const new({required this.center, required this.halfLength});

  /// The world-space center of the run.
  final Vector3 center;

  /// Half the run's length along the X axis, in world units.
  final double halfLength;
}

/// Computes the world-space placement of [run]. See [WallRunPlacement].
WallRunPlacement wallRunPlacement(
  WallRun run, {
  required int width,
  required int height,
}) {
  final centerColumn = run.startColumn + (run.length - 1) / 2;
  final center = gridCellCenter(
    centerColumn,
    run.row,
    width: width,
    height: height,
  );
  return WallRunPlacement(center: center, halfLength: run.length / 2);
}
