import 'package:tilt_domain/src/raw_gravity.dart';

/// Reads the device's raw accelerometer gravity for tilt input.
abstract interface class ITiltRepository {
  /// A stream of raw accelerometer readings.
  Stream<RawGravity> watchGravity();

  /// Whether this device reports having an accelerometer.
  ///
  /// Implementations must not throw; a missing or failed sensor resolves to
  /// false rather than an error.
  Future<bool> isAvailable();
}
