import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:test/test.dart';

const _validText = '''
# title: First Roll
# par: 20
###
#S#
#E#
###''';

void main() {
  group('LevelTextParser', () {
    late LevelTextParser parser;

    setUp(() {
      parser = LevelTextParser();
    });

    test('parses a valid level', () {
      final level = parser.parse(_validText, fileName: 'first_roll.txt');

      expect(level.id, 'first_roll');
      expect(level.title, 'First Roll');
      expect(level.par, const Duration(seconds: 20));
      expect(level.width, 3);
      expect(level.height, 4);
      expect(level.start, const GridPoint(column: 1, row: 1));
      expect(level.exit, const GridPoint(column: 1, row: 2));
      expect(level.holes, isEmpty);
    });

    test('parses a level with no par header', () {
      const text = '''
# title: No Par
###
#S#
#E#
###''';

      final level = parser.parse(text, fileName: 'no_par.txt');

      expect(level.par, isNull);
    });

    test('parses holes', () {
      const text = '''
# title: Holes
####
#SO#
#OE#
####''';

      final level = parser.parse(text, fileName: 'holes.txt');

      expect(level.holes, [
        const GridPoint(column: 2, row: 1),
        const GridPoint(column: 1, row: 2),
      ]);
    });

    test('merges horizontal wall runs on the same row', () {
      const text = '''
# title: Runs
#####
#S..#
#.#.#
#..E#
#####''';

      final level = parser.parse(text, fileName: 'runs.txt');

      expect(level.walls, [
        const WallRun(row: 0, startColumn: 0, length: 5),
        const WallRun(row: 1, startColumn: 0, length: 1),
        const WallRun(row: 1, startColumn: 4, length: 1),
        const WallRun(row: 2, startColumn: 0, length: 1),
        const WallRun(row: 2, startColumn: 2, length: 1),
        const WallRun(row: 2, startColumn: 4, length: 1),
        const WallRun(row: 3, startColumn: 0, length: 1),
        const WallRun(row: 3, startColumn: 4, length: 1),
        const WallRun(row: 4, startColumn: 0, length: 5),
      ]);
    });

    test('does not merge wall runs across rows', () {
      const text = '''
# title: No Vertical Merge
###
#S#
#.#
#E#
###''';

      final level = parser.parse(text, fileName: 'no_vertical.txt');

      expect(level.walls, [
        const WallRun(row: 0, startColumn: 0, length: 3),
        const WallRun(row: 1, startColumn: 0, length: 1),
        const WallRun(row: 1, startColumn: 2, length: 1),
        const WallRun(row: 2, startColumn: 0, length: 1),
        const WallRun(row: 2, startColumn: 2, length: 1),
        const WallRun(row: 3, startColumn: 0, length: 1),
        const WallRun(row: 3, startColumn: 2, length: 1),
        const WallRun(row: 4, startColumn: 0, length: 3),
      ]);
    });

    test('throws for a missing title header', () {
      const text = '''
###
#S#
#E#
###''';

      expect(
        () => parser.parse(text, fileName: 'missing_title.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 1)
              .having((e) => e.column, 'column', 1)
              .having((e) => e.reason, 'reason', contains('title')),
        ),
      );
    });

    test('throws for a missing start cell', () {
      const text = '''
# title: No Start
###
#.#
#E#
###''';

      expect(
        () => parser.parse(text, fileName: 'no_start.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 2)
              .having((e) => e.column, 'column', 1)
              .having((e) => e.reason, 'reason', contains('start')),
        ),
      );
    });

    test('throws for a missing exit cell', () {
      const text = '''
# title: No Exit
###
#S#
#.#
###''';

      expect(
        () => parser.parse(text, fileName: 'no_exit.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 2)
              .having((e) => e.column, 'column', 1)
              .having((e) => e.reason, 'reason', contains('exit')),
        ),
      );
    });

    test('throws for a duplicate start cell', () {
      const text = '''
# title: Dup Start
####
#SS#
#.E#
####''';

      expect(
        () => parser.parse(text, fileName: 'dup_start.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 3)
              .having((e) => e.column, 'column', 3)
              .having((e) => e.reason, 'reason', contains('duplicate start')),
        ),
      );
    });

    test('throws for a duplicate exit cell', () {
      const text = '''
# title: Dup Exit
####
#SE#
#.E#
####''';

      expect(
        () => parser.parse(text, fileName: 'dup_exit.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 4)
              .having((e) => e.column, 'column', 3)
              .having((e) => e.reason, 'reason', contains('duplicate exit')),
        ),
      );
    });

    test('throws for a ragged row', () {
      const text = '''
# title: Ragged
###
#S#
#E
###''';

      expect(
        () => parser.parse(text, fileName: 'ragged.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 4)
              .having((e) => e.column, 'column', 3)
              .having((e) => e.reason, 'reason', contains('ragged row')),
        ),
      );
    });

    test('throws for an unknown character', () {
      const text = '''
# title: Unknown Char
###
#S#
#X#
#E#
###''';

      expect(
        () => parser.parse(text, fileName: 'unknown_char.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 4)
              .having((e) => e.column, 'column', 2)
              .having((e) => e.reason, 'reason', contains('unknown character')),
        ),
      );
    });

    test('throws for a non-numeric par', () {
      const text = '''
# title: Bad Par
# par: soon
###
#S#
#E#
###''';

      expect(
        () => parser.parse(text, fileName: 'bad_par.txt'),
        throwsA(
          isA<LevelFormatException>()
              .having((e) => e.line, 'line', 2)
              .having((e) => e.column, 'column', 8)
              .having((e) => e.reason, 'reason', contains('invalid par')),
        ),
      );
    });

    test('throws for a zero or negative par', () {
      const text = '''
# title: Zero Par
# par: 0
###
#S#
#E#
###''';

      expect(
        () => parser.parse(text, fileName: 'zero_par.txt'),
        throwsA(isA<LevelFormatException>().having((e) => e.line, 'line', 2)),
      );
    });
  });
}
