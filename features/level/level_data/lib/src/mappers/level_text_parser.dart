import 'package:level_domain/level_domain.dart';

const _allowedCells = {'#', '.', 'S', 'E', 'O'};
final _headerPattern = RegExp(r'^#\s+([A-Za-z]+):\s*(.*)$');
final _digitsPattern = RegExp(r'^\d+$');

/// Parses a level's ASCII text into a [Level].
///
/// The text is a `# key: value` header block (`title` required, `par`
/// optional, in seconds) followed by an equal-width grid of `#`/`.`/`S`/
/// `E`/`O` cells. Row 0 of the grid is the far edge of the board.
///
/// Every failure raises a [LevelFormatException] carrying the 1-based line
/// and column in the source file, counting header lines.
class LevelTextParser {
  /// Parses [text], sourced from [fileName], into a [Level].
  ///
  /// The level's id is [fileName] without its extension.
  Level parse(String text, {required String fileName}) {
    final lines = text.split('\n').map(_stripTrailingCr).toList();
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    var index = 0;
    String? title;
    Duration? par;
    while (index < lines.length) {
      final match = _headerPattern.firstMatch(lines[index]);
      if (match == null) break;
      final lineNumber = index + 1;
      final key = match.group(1)!;
      final value = match.group(2)!;
      // Group 2 runs to the end of the line, so its start column is the
      // line's length minus the value's length.
      final valueColumn = lines[index].length - value.length + 1;
      switch (key) {
        case 'title':
          title = value;
        case 'par':
          par = _parsePar(value, fileName, lineNumber, valueColumn);
      }
      index++;
    }

    if (title == null || title.isEmpty) {
      throw LevelFormatException(
        file: fileName,
        line: 1,
        column: 1,
        reason: "missing required header 'title'",
      );
    }

    final gridStartLine = index + 1;
    final gridLines = lines.sublist(index);
    if (gridLines.isEmpty) {
      throw LevelFormatException(
        file: fileName,
        line: gridStartLine,
        column: 1,
        reason: 'missing grid',
      );
    }

    final width = gridLines.first.length;
    GridPoint? start;
    GridPoint? exit;
    final holes = <GridPoint>[];
    final walls = <WallRun>[];

    for (var row = 0; row < gridLines.length; row++) {
      final line = gridLines[row];
      final lineNumber = gridStartLine + row;

      if (line.length != width) {
        throw LevelFormatException(
          file: fileName,
          line: lineNumber,
          column: (line.length < width ? line.length : width) + 1,
          reason: 'ragged row: expected $width columns, found ${line.length}',
        );
      }

      var runStart = -1;
      for (var column = 0; column <= line.length; column++) {
        final cell = column < line.length ? line[column] : null;
        if (cell == '#') {
          if (runStart == -1) runStart = column;
          continue;
        }
        if (runStart != -1) {
          walls.add(
            WallRun(row: row, startColumn: runStart, length: column - runStart),
          );
          runStart = -1;
        }
        if (cell == null) continue;

        if (!_allowedCells.contains(cell)) {
          throw LevelFormatException(
            file: fileName,
            line: lineNumber,
            column: column + 1,
            reason: 'unknown character "$cell"',
          );
        }

        switch (cell) {
          case 'S':
            if (start != null) {
              throw LevelFormatException(
                file: fileName,
                line: lineNumber,
                column: column + 1,
                reason: 'duplicate start cell (S)',
              );
            }
            start = GridPoint(column: column, row: row);
          case 'E':
            if (exit != null) {
              throw LevelFormatException(
                file: fileName,
                line: lineNumber,
                column: column + 1,
                reason: 'duplicate exit cell (E)',
              );
            }
            exit = GridPoint(column: column, row: row);
          case 'O':
            holes.add(GridPoint(column: column, row: row));
        }
      }
    }

    if (start == null) {
      throw LevelFormatException(
        file: fileName,
        line: gridStartLine,
        column: 1,
        reason: 'missing start cell (S)',
      );
    }
    if (exit == null) {
      throw LevelFormatException(
        file: fileName,
        line: gridStartLine,
        column: 1,
        reason: 'missing exit cell (E)',
      );
    }

    return Level(
      id: _idFor(fileName),
      title: title,
      par: par,
      width: width,
      height: gridLines.length,
      start: start,
      exit: exit,
      holes: holes,
      walls: walls,
    );
  }

  Duration? _parsePar(String value, String fileName, int line, int column) {
    if (!_digitsPattern.hasMatch(value) || int.parse(value) <= 0) {
      throw LevelFormatException(
        file: fileName,
        line: line,
        column: column,
        reason: 'invalid par: "$value" is not a positive integer',
      );
    }
    return Duration(seconds: int.parse(value));
  }

  String _idFor(String fileName) {
    final base = fileName.split('/').last;
    final dot = base.lastIndexOf('.');
    return dot == -1 ? base : base.substring(0, dot);
  }
}

String _stripTrailingCr(String line) =>
    line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
