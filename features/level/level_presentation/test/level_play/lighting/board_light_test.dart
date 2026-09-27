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

    group('smoothTowards', () {
      final target = Tilt(x: 0.2, y: -0.1);

      test('moves part of the way toward the target in one frame', () {
        final next = light.smoothTowards(
          Tilt.flat,
          target,
          const Duration(milliseconds: 16),
        );

        expect(next.x, greaterThan(0));
        expect(next.x, lessThan(target.x));
        expect(next.y, lessThan(0));
        expect(next.y, greaterThan(target.y));
      });

      test('does not move with zero elapsed time', () {
        final next = light.smoothTowards(Tilt.flat, target, Duration.zero);

        expect(next, Tilt.flat);
      });

      test('is frame-rate independent', () {
        var byHalves = Tilt.flat;
        for (var i = 0; i < 2; i++) {
          byHalves = light.smoothTowards(
            byHalves,
            target,
            const Duration(milliseconds: 8),
          );
        }
        final whole = light.smoothTowards(
          Tilt.flat,
          target,
          const Duration(milliseconds: 16),
        );

        expect(byHalves.x, closeTo(whole.x, 1e-9));
        expect(byHalves.y, closeTo(whole.y, 1e-9));
      });

      test('converges on the target', () {
        final next = light.smoothTowards(
          Tilt.flat,
          target,
          const Duration(seconds: 2),
        );

        expect(next.x, closeTo(target.x, 1e-4));
        expect(next.y, closeTo(target.y, 1e-4));
      });
    });
  });
}
