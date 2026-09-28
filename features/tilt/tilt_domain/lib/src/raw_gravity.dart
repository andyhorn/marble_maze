import 'package:meta/meta.dart';

/// A single accelerometer reading, in m/s^2, including the reaction to
/// gravity.
///
/// At rest, the accelerometer reads +g on whichever device axis currently
/// points up (opposing gravity); [x] is screen right, [y] is up the screen,
/// [z] is out of the screen.
@immutable
class RawGravity {
  /// Creates a raw gravity reading.
  const new({required this.x, required this.y, required this.z});

  /// No reading recorded yet.
  static const RawGravity zero = RawGravity(x: 0, y: 0, z: 0);

  /// A device lying flat and still, face up: gravity entirely along the
  /// out-of-screen axis.
  static const RawGravity flat = RawGravity(x: 0, y: 0, z: 9.81);

  /// Acceleration along the device's x axis (screen right), in m/s^2.
  final double x;

  /// Acceleration along the device's y axis (up the screen), in m/s^2.
  final double y;

  /// Acceleration along the device's z axis (out of the screen), in m/s^2.
  final double z;

  @override
  bool operator ==(Object other) =>
      other is RawGravity && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'RawGravity(x: $x, y: $y, z: $z)';
}
