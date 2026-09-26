import 'package:meta/meta.dart';

/// A horizontal run of adjacent wall cells on [row], merged into a single
/// collider starting at [startColumn] and spanning [length] cells.
@immutable
class WallRun {
  /// Creates a wall run on [row], from [startColumn] for [length] cells.
  const new({
    required this.row,
    required this.startColumn,
    required this.length,
  });

  /// The row the run occupies.
  final int row;

  /// The column of the first cell in the run.
  final int startColumn;

  /// The number of cells the run spans.
  final int length;

  @override
  bool operator ==(Object other) =>
      other is WallRun &&
      other.row == row &&
      other.startColumn == startColumn &&
      other.length == length;

  @override
  int get hashCode => Object.hash(row, startColumn, length);

  @override
  String toString() =>
      'WallRun(row: $row, startColumn: $startColumn, length: $length)';
}
