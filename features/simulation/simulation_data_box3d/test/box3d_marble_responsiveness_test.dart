import 'dart:math' as math;

import 'package:box3d/box3d.dart';
import 'package:level_domain/level_domain.dart';
import 'package:simulation_data_box3d/simulation_data_box3d.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:test/test.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

const _frame = Duration(milliseconds: 16);
const _settleTime = Duration(milliseconds: 1000);
const double _fiveDegrees = 5 * math.pi / 180;

// Wide enough that the marble never reaches the border wall within the
// 3-second top-speed scenario below, even at the fastest terminal speed
// tuning allows (maxSpeed 12 u/s).
Level _flatLevel() => const Level(
  id: 'responsiveness-test',
  title: 'Responsiveness Test',
  width: 100,
  height: 100,
  start: GridPoint(column: 50, row: 50),
  exit: GridPoint(column: 99, row: 99),
  holes: <GridPoint>[],
  walls: <WallRun>[],
);

/// Steps [simulation] under [tilt] one frame at a time, up to [timeout],
/// stopping as soon as [reached] the marble's velocity satisfies [reached].
/// Returns the elapsed time once reached, or null if [timeout] passed first.
Duration? _stepUntil(
  IMarbleSimulation simulation,
  Tilt tilt,
  Duration timeout,
  bool Function(Vector3 velocity) reached,
) {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    simulation.step(tilt, _frame);
    elapsed += _frame;
    if (reached(simulation.marble.velocity)) return elapsed;
  }
  return null;
}

void main() {
  setUpAll(Box3d.ensureInitialized);

  late Box3dMarbleSimulation simulation;

  setUp(() {
    simulation = Box3dMarbleSimulation()..load(_flatLevel());
    // Let a freshly loaded (possibly sleeping) marble settle before each
    // scenario, matching the contract suite's setup.
    var remaining = _settleTime;
    while (remaining > Duration.zero) {
      final step = remaining < _frame ? remaining : _frame;
      simulation.step(Tilt.flat, step);
      remaining -= step;
    }
  });

  tearDown(() {
    simulation.dispose();
  });

  test('start-up: reaches 2 u/s within 0.5s of a 5deg tilt', () {
    final elapsed = _stepUntil(
      simulation,
      Tilt(x: _fiveDegrees, y: 0),
      const Duration(milliseconds: 500),
      (v) => v.x >= 2,
    );

    expect(
      elapsed,
      isNotNull,
      reason: 'marble never reached 2 u/s within 0.5s',
    );
    expect(elapsed, lessThanOrEqualTo(const Duration(milliseconds: 500)));
  });

  test('reversal: reverses from +2 u/s to -2 u/s within 1.0s', () {
    // Get the marble rolling at ~+2 u/s by tilting +5deg, so its spin
    // matches rolling rather than being set directly.
    final rollTime = _stepUntil(
      simulation,
      Tilt(x: _fiveDegrees, y: 0),
      const Duration(seconds: 2),
      (v) => v.x >= 2,
    );
    expect(
      rollTime,
      isNotNull,
      reason: 'marble never reached +2 u/s to set up the reversal',
    );

    final elapsed = _stepUntil(
      simulation,
      Tilt(x: -_fiveDegrees, y: 0),
      const Duration(milliseconds: 1000),
      (v) => v.x <= -2,
    );

    expect(
      elapsed,
      isNotNull,
      reason: 'marble never reversed to -2 u/s within 1.0s',
    );
    expect(elapsed, lessThanOrEqualTo(const Duration(milliseconds: 1000)));
  });

  test('top speed: stays under maxSpeed and settles between 5-10 u/s', () {
    var remaining = const Duration(seconds: 3);
    var peakSpeed = 0.0;
    while (remaining > Duration.zero) {
      final step = remaining < _frame ? remaining : _frame;
      simulation.step(Tilt(x: Tilt.maxTilt, y: 0), step);
      remaining -= step;
      final speed = simulation.marble.velocity.length;
      if (speed > peakSpeed) peakSpeed = speed;
      expect(speed, lessThanOrEqualTo(simulation.config.maxSpeed + 1e-3));
    }

    final terminalSpeed = simulation.marble.velocity.length;
    expect(terminalSpeed, greaterThan(5));
    expect(terminalSpeed, lessThan(10));
  });
}
