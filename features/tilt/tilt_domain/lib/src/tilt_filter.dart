import 'dart:math' as math;

import 'package:tilt_domain/src/raw_gravity.dart';
import 'package:tilt_domain/src/tilt.dart';
import 'package:tilt_domain/src/tilt_filter_config.dart';

/// Turns raw accelerometer readings into a [Tilt], relative to a calibrated
/// neutral orientation.
///
/// [calibrate] records whatever angle the device is held at as flat. [filter]
/// then projects each reading onto the screen's x and y axes relative to
/// that neutral angle, applies a dead zone, clamps to [Tilt.maxTilt], and
/// low-pass smooths the result.
class TiltFilter {
  /// Creates a tilt filter with the given [config].
  new({this.config = TiltFilterConfig.standard});

  /// The tuning this filter uses.
  final TiltFilterConfig config;

  RawGravity _neutral = RawGravity.zero;
  Tilt _smoothed = Tilt.flat;

  /// Records [gravity] as the neutral ("flat") orientation, and resets the
  /// smoothed tilt so a recalibration does not glide in from the old value.
  void calibrate(RawGravity gravity) {
    _neutral = gravity;
    _smoothed = Tilt.flat;
  }

  /// Projects [gravity] onto the screen plane relative to the calibrated
  /// neutral orientation, returning the smoothed [Tilt].
  Tilt filter(RawGravity gravity) {
    final rawX =
        _screenAngle(gravity.x, gravity.z) -
        _screenAngle(_neutral.x, _neutral.z);
    final rawY =
        _screenAngle(gravity.y, gravity.z) -
        _screenAngle(_neutral.y, _neutral.z);

    final clampedX = _deadZoned(rawX).clamp(-Tilt.maxTilt, Tilt.maxTilt);
    final clampedY = _deadZoned(rawY).clamp(-Tilt.maxTilt, Tilt.maxTilt);

    return _smoothed = Tilt(
      x: _lerp(_smoothed.x, clampedX, config.smoothing),
      y: _lerp(_smoothed.y, clampedY, config.smoothing),
    );
  }

  // The accelerometer reads +g on whichever axis currently points up.
  // Tilting a screen edge down rotates its axis away from up, so that
  // axis's reading drops below neutral; negating it turns "edge down" into
  // a positive angle, matching Tilt's sign convention. Read relative to the
  // out-of-screen axis (which stays close to +g for the small tilts this
  // game allows) rather than the reading's magnitude, so a light shake
  // doesn't scale the angle.
  double _screenAngle(double screenAxis, double outOfScreenAxis) =>
      math.atan2(-screenAxis, outOfScreenAxis);

  double _deadZoned(double angle) => angle.abs() < config.deadZone ? 0 : angle;

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
