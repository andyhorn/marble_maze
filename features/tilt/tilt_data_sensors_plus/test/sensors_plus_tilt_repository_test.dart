import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tilt_data_sensors_plus/tilt_data_sensors_plus.dart';

AccelerometerEvent _event({double x = 0, double y = 0, double z = 9.81}) =>
    AccelerometerEvent(x, y, z, DateTime(2026));

void main() {
  group('SensorsPlusTiltRepository', () {
    test('watchGravity maps accelerometer events to raw gravity', () async {
      final repository = SensorsPlusTiltRepository(
        accelerometerStreamSource: ({samplingPeriod = Duration.zero}) =>
            Stream.value(_event(x: 1, y: 2, z: 3)),
      );

      final gravity = await repository.watchGravity().first;

      expect(gravity.x, 1);
      expect(gravity.y, 2);
      expect(gravity.z, 3);
    });

    test('isAvailable is true once an event arrives', () async {
      final repository = SensorsPlusTiltRepository(
        accelerometerStreamSource: ({samplingPeriod = Duration.zero}) =>
            Stream.value(_event()),
      );

      expect(await repository.isAvailable(), isTrue);
    });

    test('isAvailable is false when the stream errors', () async {
      final repository = SensorsPlusTiltRepository(
        accelerometerStreamSource: ({samplingPeriod = Duration.zero}) =>
            Stream.error(Exception('no sensor')),
      );

      expect(await repository.isAvailable(), isFalse);
    });

    test('isAvailable is false, and does not throw, when nothing arrives '
        'within the probe timeout', () async {
      final repository = SensorsPlusTiltRepository(
        availabilityProbeTimeout: const Duration(milliseconds: 1),
        accelerometerStreamSource: ({samplingPeriod = Duration.zero}) =>
            const Stream<AccelerometerEvent>.empty(),
      );

      expect(await repository.isAvailable(), isFalse);
    });
  });
}
