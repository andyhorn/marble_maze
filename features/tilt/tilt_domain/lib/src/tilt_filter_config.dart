import 'dart:math' as math;

/// Tuning constants for `TiltFilter`.
class TiltFilterConfig {
  /// Creates a tilt filter config.
  const new({this.deadZone = _oneDegree, this.smoothing = 0.25});

  static const double _oneDegree = math.pi / 180;

  /// The default tuning.
  static const TiltFilterConfig standard = TiltFilterConfig();

  /// Tilt angles smaller than this, in radians, are treated as flat.
  final double deadZone;

  /// The low-pass smoothing factor applied on each `TiltFilter.filter`
  /// call: how much of the new reading to blend in, from 0 (frozen) to 1
  /// (unsmoothed).
  final double smoothing;
}
