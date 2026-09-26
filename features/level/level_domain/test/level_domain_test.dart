import 'package:level_domain/level_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GridPoint', () {
    test('supports value equality', () {
      expect(
        const GridPoint(column: 1, row: 2),
        const GridPoint(column: 1, row: 2),
      );
      expect(
        const GridPoint(column: 1, row: 2),
        isNot(const GridPoint(column: 2, row: 1)),
      );
    });
  });

  group('WallRun', () {
    test('supports value equality', () {
      expect(
        const WallRun(row: 0, startColumn: 1, length: 3),
        const WallRun(row: 0, startColumn: 1, length: 3),
      );
      expect(
        const WallRun(row: 0, startColumn: 1, length: 3),
        isNot(const WallRun(row: 0, startColumn: 1, length: 4)),
      );
    });
  });

  group('Level', () {
    Level buildLevel({List<GridPoint> holes = const []}) => Level(
      id: 'first_roll',
      title: 'First Roll',
      par: const Duration(seconds: 20),
      width: 3,
      height: 3,
      start: const GridPoint(column: 0, row: 0),
      exit: const GridPoint(column: 2, row: 2),
      holes: holes,
      walls: const [WallRun(row: 0, startColumn: 0, length: 3)],
    );

    test('supports value equality', () {
      expect(buildLevel(), buildLevel());
    });

    test('differs when holes differ', () {
      expect(
        buildLevel(),
        isNot(buildLevel(holes: const [GridPoint(column: 1, row: 1)])),
      );
    });
  });

  group('LevelManifestEntry', () {
    test('supports value equality', () {
      expect(
        const LevelManifestEntry(
          id: 'a',
          title: 'A',
          par: Duration(seconds: 1),
        ),
        const LevelManifestEntry(
          id: 'a',
          title: 'A',
          par: Duration(seconds: 1),
        ),
      );
      expect(
        const LevelManifestEntry(id: 'a', title: 'A'),
        isNot(const LevelManifestEntry(id: 'b', title: 'A')),
      );
    });
  });

  group('LevelFormatException', () {
    test('formats as file:line:column: reason', () {
      const exception = LevelFormatException(
        file: 'first_roll.txt',
        line: 3,
        column: 5,
        reason: 'duplicate start cell',
      );
      expect(exception.toString(), 'first_roll.txt:3:5: duplicate start cell');
    });
  });

  group('LevelNotFoundException', () {
    test('carries the unknown id', () {
      const exception = LevelNotFoundException('missing');
      expect(exception.id, 'missing');
    });
  });
}
