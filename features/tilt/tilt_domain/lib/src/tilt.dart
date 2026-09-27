import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The board's tilt, in radians around the X and Z screen axes.
///
/// Positive [x] rolls the marble toward +X (screen right). Positive [y]
/// tilts the far edge of the board down, rolling the marble toward +Z
/// (screen up).
@immutable
class Tilt {
  /// Creates a tilt, clamping [x] and [y] to +/- [maxTilt].
  ///
  /// Factory and named constructors cannot use the `new`-only shorthand,
  /// so the type name stays here.
  // ignore: unnecessary_type_name_in_constructor
  factory Tilt({required double x, required double y}) =>
      Tilt._(x.clamp(-maxTilt, maxTilt), y.clamp(-maxTilt, maxTilt));

  // Named constructors can't drop the class name.
  // ignore: unnecessary_type_name_in_constructor
  const Tilt._(this.x, this.y);

  /// The maximum tilt magnitude, in radians (15 degrees).
  static const double maxTilt = 15 * math.pi / 180;

  /// No tilt.
  static const Tilt flat = Tilt._(0, 0);

  /// The tilt around the screen's horizontal axis, in radians.
  final double x;

  /// The tilt around the screen's vertical axis, in radians.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is Tilt && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Tilt(x: $x, y: $y)';
}
