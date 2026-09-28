import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilt_domain/tilt_domain.dart';

class _MockTiltRepository extends Mock implements ITiltRepository;

RawGravity _tiltedRight(double angle) =>
    RawGravity(x: 9.81 * math.sin(angle), y: 0, z: 9.81 * math.cos(angle));

void main() {
  group('BubbleLevelCubit', () {
    late _MockTiltRepository tiltRepository;
    late StreamController<RawGravity> gravity;
    late BubbleLevelCubit cubit;

    setUp(() {
      tiltRepository = _MockTiltRepository();
      gravity = StreamController<RawGravity>();
      when(() => tiltRepository.watchGravity())
          .thenAnswer((_) => gravity.stream);
      cubit = BubbleLevelCubit(tiltRepository: tiltRepository);
    });

    tearDown(() async {
      await cubit.close();
      await gravity.close();
    });

    test('starts without a reading', () {
      expect(cubit.state, const BubbleLevelState());
    });

    test('reads a device lying flat as zero tilt', () async {
      gravity.add(const RawGravity(x: 0, y: 0, z: 9.81));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.hasReading, isTrue);
      expect(cubit.state.xAngle, 0);
      expect(cubit.state.yAngle, 0);
    });

    test('reads a raised right edge as a positive x angle', () async {
      const angle = 10 * math.pi / 180;
      gravity.add(_tiltedRight(angle));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.xAngle, closeTo(angle, 1e-9));
      expect(cubit.state.yAngle, 0);
    });

    test('smooths later readings toward the new angle', () async {
      const angle = 10 * math.pi / 180;
      gravity.add(const RawGravity(x: 0, y: 0, z: 9.81));
      await Future<void>.delayed(Duration.zero);
      gravity.add(_tiltedRight(angle));
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.xAngle,
        closeTo(angle * BubbleLevelCubit.smoothing, 1e-9),
      );
    });

    test('cancels its subscription when closed', () async {
      await cubit.close();

      expect(gravity.hasListener, isFalse);
    });
  });
}
