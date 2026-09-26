import 'package:meta/meta.dart';

/// A single cell in a level's grid, addressed by [column] and [row].
///
/// Row 0 is the far edge of the board (the top of the screen).
@immutable
class GridPoint {
  /// Creates a grid point at [column], [row].
  const new({required this.column, required this.row});

  /// The zero-based column, increasing to the right.
  final int column;

  /// The zero-based row, increasing toward the near edge of the board.
  final int row;

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'GridPoint(column: $column, row: $row)';
}
