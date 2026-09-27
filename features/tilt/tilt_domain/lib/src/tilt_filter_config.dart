import 'dart:math' as math;

/// Tuning constants for `TiltFilter`.
class TiltFilterConfig {
  /// Creates a tilt filter config.
  const new({this.deadZone = _threeDegrees, this.smoothing = 0.5});

  static const double _threeDegrees = 3 * math.pi / 180;

  /// The default tuning.
  static const TiltFilterConfig standard = TiltFilterConfig();

  /// Tilt angles smaller than this, in radians, are treated as flat.
  ///
  /// `3°`: the marble stays put through the small wobbles of holding a
  /// phone and only rolls once the player deliberately tilts it.
  final double deadZone;

  /// The low-pass smoothing factor applied on each `TiltFilter.filter`
  /// call: how much of the new reading to blend in, from 0 (frozen) to 1
  /// (unsmoothed).
  ///
  /// `0.5`: about 30ms of lag at the accelerometer's 50Hz sampling rate,
  /// short enough that tilt feels immediate while still smoothing sensor
  /// noise.
  final double smoothing;
}
