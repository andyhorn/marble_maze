import 'package:level_domain/level_domain.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:test/test.dart';

void main() {
  group('gridCellCenter', () {
    test('centers the board on the origin', () {
      final center = gridCellCenter(4, 4, width: 9, height: 9);

      expect(center.x, 0);
      expect(center.z, 0);
    });

    test('row 0 is the most positive Z (the far edge)', () {
      final farEdge = gridCellCenter(0, 0, width: 9, height: 9);
      final nearEdge = gridCellCenter(0, 8, width: 9, height: 9);

      expect(farEdge.z, greaterThan(nearEdge.z));
    });

    test('column 0 is the most negative X', () {
      final left = gridCellCenter(0, 0, width: 9, height: 9);
      final right = gridCellCenter(8, 0, width: 9, height: 9);

      expect(left.x, lessThan(right.x));
    });
  });

  group('wallRunPlacement', () {
    test('centers on the run and reports its half-length', () {
      const run = WallRun(row: 0, startColumn: 1, length: 3);

      final placement = wallRunPlacement(run, width: 9, height: 9);

      expect(placement.center.x, gridCellCenter(2, 0, width: 9, height: 9).x);
      expect(placement.halfLength, 1.5);
    });
  });
}
