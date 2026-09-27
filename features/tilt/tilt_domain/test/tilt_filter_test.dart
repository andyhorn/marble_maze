import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:tilt_domain/tilt_domain.dart';

// No smoothing, so filter() returns the clamped/dead-zoned angle exactly,
// letting these tests assert precise values. Convergence with the standard
// smoothing config is covered separately.
const _unsmoothed = TiltFilterConfig(smoothing: 1);

RawGravity _flat({double g = 9.81}) => RawGravity(x: 0, y: 0, z: g);

// A reading as if the device's right edge were tilted down by [degrees]
// from flat, holding the top edge level.
RawGravity _rightDown(double degrees, {double g = 9.81}) {
  final radians = degrees * math.pi / 180;
  return RawGravity(x: -g * math.sin(radians), y: 0, z: g * math.cos(radians));
}

// A reading as if the device's top (far) edge were tilted down by
// [degrees] from flat, holding the right edge level.
RawGravity _topDown(double degrees, {double g = 9.81}) {
  final radians = degrees * math.pi / 180;
  return RawGravity(x: 0, y: -g * math.sin(radians), z: g * math.cos(radians));
}

void main() {
  group('TiltFilter', () {
    late TiltFilter filter;

    setUp(() {
      filter = TiltFilter(config: _unsmoothed);
    });

    test('an uncalibrated flat reading is flat', () {
      expect(filter.filter(_flat()), Tilt.flat);
    });

    test('calibration: the calibrated reading maps to flat', () {
      filter.calibrate(_rightDown(6));

      expect(filter.filter(_rightDown(6)), Tilt.flat);
    });

    test('recalibrating resets the smoothed tilt to flat', () {
      final smoothing = TiltFilter()
        ..calibrate(_flat())
        ..filter(_rightDown(10))
        ..calibrate(_flat());

      expect(smoothing.filter(_flat()), Tilt.flat);
    });

    test('tilting the right edge down gives positive x', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_rightDown(6));

      expect(tilt.x, greaterThan(0));
      expect(tilt.y, closeTo(0, 1e-9));
    });

    test('tilting the left edge down gives negative x', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_rightDown(-6));

      expect(tilt.x, lessThan(0));
    });

    test('tilting the top edge down gives positive y', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_topDown(6));

      expect(tilt.y, greaterThan(0));
      expect(tilt.x, closeTo(0, 1e-9));
    });

    test('a right-edge tilt on a pitched neutral still gives pure x', () {
      final neutral = _topDown(20);
      filter.calibrate(neutral);

      // Compose the same pitch with an added roll, as a real reading would
      // arrive: roll about the device's current "up the screen" axis.
      const rollDegrees = 8.0;
      const rollRadians = rollDegrees * math.pi / 180;
      const pitchRadians = 20 * math.pi / 180;
      final rolled = RawGravity(
        x: -9.81 * math.sin(rollRadians) * math.cos(pitchRadians),
        y: -9.81 * math.sin(pitchRadians),
        z: 9.81 * math.cos(pitchRadians) * math.cos(rollRadians),
      );

      final tilt = filter.filter(rolled);

      expect(tilt.x, closeTo(rollRadians, 1e-9));
    });

    test('a reading within the dead zone is flat', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_rightDown(2.5));

      expect(tilt, Tilt.flat);
    });

    test('a reading just past the dead zone is not flat', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_rightDown(3.5));

      expect(tilt.x, greaterThan(0));
    });

    test('clamps to +/- maxTilt', () {
      filter.calibrate(_flat());

      final tilt = filter.filter(_rightDown(45));

      expect(tilt.x, Tilt.maxTilt);
    });

    test('smoothing converges toward the target over repeated calls', () {
      final smoothed = TiltFilter()..calibrate(_flat());

      var last = Tilt.flat;
      for (var i = 0; i < 60; i++) {
        last = smoothed.filter(_rightDown(10));
      }

      expect(last.x, closeTo(10 * math.pi / 180, 1e-3));
    });

    test('smoothing moves gradually rather than jumping', () {
      final smoothed = TiltFilter()..calibrate(_flat());

      final first = smoothed.filter(_rightDown(10));

      expect(first.x, greaterThan(0));
      expect(first.x, lessThan(10 * math.pi / 180));
    });
  });
}
