import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:tilt_domain/tilt_domain.dart';

void main() {
  group('Tilt', () {
    test('flat has no tilt', () {
      expect(Tilt.flat.x, 0);
      expect(Tilt.flat.y, 0);
    });

    test('clamps x and y to maxTilt', () {
      final tilt = Tilt(x: 10, y: -10);

      expect(tilt.x, Tilt.maxTilt);
      expect(tilt.y, -Tilt.maxTilt);
    });

    test('maxTilt is 15 degrees', () {
      expect(Tilt.maxTilt, closeTo(15 * math.pi / 180, 1e-9));
    });

    test('supports value equality', () {
      expect(Tilt(x: 0.1, y: 0.2), Tilt(x: 0.1, y: 0.2));
      expect(Tilt(x: 0.1, y: 0.2), isNot(Tilt(x: 0.1, y: 0.3)));
    });
  });
}
