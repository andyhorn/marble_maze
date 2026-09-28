import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/board/wall_strip.dart';

Level _levelWithWalls(List<WallRun> walls) => Level(
  id: 'test',
  title: 'Test',
  width: 5,
  height: 5,
  start: const GridPoint(column: 1, row: 1),
  exit: const GridPoint(column: 3, row: 3),
  holes: const [],
  walls: walls,
);

void main() {
  group('wallStripsFor', () {
    test('keeps a multi-cell run as one horizontal strip', () {
      final strips = wallStripsFor(
        _levelWithWalls(const [WallRun(row: 0, startColumn: 0, length: 5)]),
      );

      expect(strips, hasLength(1));
      final strip = strips.single;
      expect(strip.runsAlongZ, isFalse);
      expect(strip.halfLength, 2.5);
      expect(strip.cells, [
        for (var column = 0; column < 5; column++)
          GridPoint(column: column, row: 0),
      ]);
      expect(strip.center.x, closeTo(0, 1e-6));
      expect(strip.center.z, closeTo(2, 1e-6));
    });

    test('merges one-cell runs stacked in a column into one strip', () {
      final strips = wallStripsFor(
        _levelWithWalls(const [
          WallRun(row: 1, startColumn: 0, length: 1),
          WallRun(row: 2, startColumn: 0, length: 1),
          WallRun(row: 3, startColumn: 0, length: 1),
        ]),
      );

      expect(strips, hasLength(1));
      final strip = strips.single;
      expect(strip.runsAlongZ, isTrue);
      expect(strip.halfLength, 1.5);
      expect(strip.cells, const [
        GridPoint(column: 0, row: 1),
        GridPoint(column: 0, row: 2),
        GridPoint(column: 0, row: 3),
      ]);
      expect(strip.center.x, closeTo(-2, 1e-6));
      expect(strip.center.z, closeTo(0, 1e-6));
    });

    test('splits a column where its one-cell runs are not consecutive', () {
      final strips = wallStripsFor(
        _levelWithWalls(const [
          WallRun(row: 3, startColumn: 2, length: 1),
          WallRun(row: 0, startColumn: 2, length: 1),
          WallRun(row: 1, startColumn: 2, length: 1),
        ]),
      );

      expect(
        strips.map((strip) => strip.halfLength),
        unorderedEquals([1, 0.5]),
      );
      expect(strips.every((strip) => strip.runsAlongZ), isTrue);
    });

    test('gives the same level the same grain offsets every time', () {
      const walls = [
        WallRun(row: 0, startColumn: 0, length: 5),
        WallRun(row: 2, startColumn: 1, length: 1),
      ];

      final first = wallStripsFor(_levelWithWalls(walls));
      final second = wallStripsFor(_levelWithWalls(walls));

      for (var i = 0; i < first.length; i++) {
        expect(first[i].grainOffset, second[i].grainOffset);
      }
      expect(first[0].grainOffset, isNot(first[1].grainOffset));
    });
  });
}
