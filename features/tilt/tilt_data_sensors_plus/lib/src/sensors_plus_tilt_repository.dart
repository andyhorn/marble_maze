import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart' as sensors_plus;
import 'package:tilt_domain/tilt_domain.dart';

/// The shape of `sensors_plus`'s top-level `accelerometerEventStream`,
/// injectable so tests don't touch the real plugin channel.
typedef AccelerometerStreamSource =
    Stream<sensors_plus.AccelerometerEvent> Function({Duration samplingPeriod});

/// Reads gravity from the device accelerometer via `sensors_plus`.
class SensorsPlusTiltRepository implements ITiltRepository {
  /// Creates a tilt repository sampling the accelerometer at
  /// [samplingPeriod].
  ///
  /// [accelerometerStreamSource] defaults to `sensors_plus`'s
  /// `accelerometerEventStream`; tests inject a fake so they never touch the
  /// real plugin channel.
  new({
    this.samplingPeriod = sensors_plus.SensorInterval.gameInterval,
    this.availabilityProbeTimeout = const Duration(milliseconds: 200),
    AccelerometerStreamSource accelerometerStreamSource =
        sensors_plus.accelerometerEventStream,
  }) : // External name accelerometerStreamSource is clearer at call sites
       // than the private field it initializes.
       // ignore: prefer_initializing_formals
       _accelerometerStreamSource = accelerometerStreamSource;

  /// How often the accelerometer is sampled.
  final Duration samplingPeriod;

  /// How long [isAvailable] waits for a first event or error before
  /// assuming the sensor is unavailable.
  final Duration availabilityProbeTimeout;

  final AccelerometerStreamSource _accelerometerStreamSource;

  @override
  Stream<RawGravity> watchGravity() =>
      _accelerometerStreamSource(samplingPeriod: samplingPeriod)
          .map((event) => RawGravity(x: event.x, y: event.y, z: event.z));

  // sensors_plus has no direct capability query: a missing accelerometer
  // surfaces as an error event on the stream (once the platform channel
  // round-trips), not a thrown exception, so this probes briefly instead.
  @override
  Future<bool> isAvailable() async {
    final completer = Completer<bool>();
    final timer = Timer(availabilityProbeTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final subscription = watchGravity().listen(
      (_) {
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (Object _) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    final available = await completer.future;
    timer.cancel();
    await subscription.cancel();
    return available;
  }
}
