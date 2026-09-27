import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_play/lighting/board_light.dart';
import 'package:tilt_domain/tilt_domain.dart';

void main() {
  group('BoardLight', () {
    const light = BoardLight();

    test('flat tilt gives the base direction', () {
      final direction = light.directionFor(Tilt.flat);

      // `Vector3` stores components as `double`-precision-narrowing
      // `Float32List`, so an exact `double` literal like `baseX` can come
      // back very slightly off.
      expect(direction.x, closeTo(light.baseX, 1e-6));
      expect(direction.y, closeTo(light.baseY, 1e-6));
      expect(direction.z, closeTo(light.baseZ, 1e-6));
    });

    test('increasing tilt.x increases direction.x toward the downhill '
        'direction', () {
      final flatX = light.directionFor(Tilt.flat).x;
      final tiltedX = light.directionFor(Tilt(x: 0.2, y: 0)).x;

      expect(tiltedX, greaterThan(flatX));
    });

    test('decreasing tilt.x (tilting the other way) decreases direction.x', () {
      final flatX = light.directionFor(Tilt.flat).x;
      final tiltedX = light.directionFor(Tilt(x: -0.2, y: 0)).x;

      expect(tiltedX, lessThan(flatX));
    });

    test('increasing tilt.y increases direction.z toward the downhill '
        'direction', () {
      final flatZ = light.directionFor(Tilt.flat).z;
      final tiltedZ = light.directionFor(Tilt(x: 0, y: 0.2)).z;

      expect(tiltedZ, greaterThan(flatZ));
    });

    test('decreasing tilt.y decreases direction.z', () {
      final flatZ = light.directionFor(Tilt.flat).z;
      final tiltedZ = light.directionFor(Tilt(x: 0, y: -0.2)).z;

      expect(tiltedZ, lessThan(flatZ));
    });

    test('tilt never changes the vertical component', () {
      final direction = light.directionFor(Tilt(x: 0.2, y: -0.2));

      expect(direction.y, closeTo(light.baseY, 1e-6));
    });
  });
}
