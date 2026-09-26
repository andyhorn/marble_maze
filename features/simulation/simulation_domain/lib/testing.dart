/// A reusable contract test suite for [IMarbleSimulation] implementations.
///
/// A physics backend's own test suite calls [runMarbleSimulationContractTests]
/// with a factory that builds a fresh [MarbleSimulationHarness] for each
/// test.
library;

import 'package:level_domain/level_domain.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:test/test.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

/// A simulation under test, paired with the [MarbleTestHandle] the contract
/// suite uses to set up each scenario.
class MarbleSimulationHarness {
  /// Creates a contract-test harness.
  const new({
    required this.simulation,
    required this.handle,
    required this.maxSpeed,
  });

  /// The simulation under test.
  final IMarbleSimulation simulation;

  /// The backend's hook for placing/moving the marble directly.
  final MarbleTestHandle handle;

  /// The backend's configured maximum marble speed, in units per second.
  final double maxSpeed;
}

const _frame = Duration(milliseconds: 16);
const _settleTime = Duration(milliseconds: 1000);
const _rollTime = Duration(milliseconds: 500);
const _rollTilt = 0.15;

// Long enough for a marble launched two cells from a hole to reach its centre
// once friction has turned the launch into rolling.
const _holeApproachTime = Duration(milliseconds: 1500);

Level _flatLevel() => const Level(
  id: 'contract-test',
  title: 'Contract Test',
  width: 9,
  height: 9,
  start: GridPoint(column: 4, row: 4),
  exit: GridPoint(column: 8, row: 8),
  holes: [],
  walls: [],
);

/// A level with a single wall cell two columns right of the start cell, on
/// the same row so the marble can be launched straight into it.
Level _wallLevel() => const Level(
  id: 'contract-test-wall',
  title: 'Contract Test Wall',
  width: 9,
  height: 9,
  start: GridPoint(column: 4, row: 4),
  exit: GridPoint(column: 8, row: 8),
  holes: [],
  walls: [WallRun(row: 4, startColumn: 7, length: 1)],
);

/// The wall cell's world-space X coordinate in [_wallLevel], per
/// [gridCellCenter]'s board-centering formula.
const _wallX = 3.0;

/// A level with a single hole two columns right of the start cell, on the
/// same row so the marble can be rolled straight into it.
Level _holeLevel() => const Level(
  id: 'contract-test-hole',
  title: 'Contract Test Hole',
  width: 9,
  height: 9,
  start: GridPoint(column: 4, row: 4),
  exit: GridPoint(column: 8, row: 8),
  holes: [_hole],
  walls: [],
);

const _hole = GridPoint(column: 6, row: 4);

/// The hole cell's world-space X coordinate in [_holeLevel], per
/// [gridCellCenter]'s board-centering formula.
const _holeX = 2.0;

void _stepFor(IMarbleSimulation simulation, Tilt tilt, Duration duration) {
  var remaining = duration;
  while (remaining > Duration.zero) {
    final step = remaining < _frame ? remaining : _frame;
    simulation.step(tilt, step);
    remaining -= step;
  }
}

/// Runs the [IMarbleSimulation] contract tests against harnesses built by
/// [create], one fresh harness per test.
void runMarbleSimulationContractTests(
  MarbleSimulationHarness Function() create,
) {
  group('IMarbleSimulation contract', () {
    late MarbleSimulationHarness harness;

    setUp(() {
      harness = create();
      harness.simulation.load(_flatLevel());
      // A freshly loaded marble may be asleep at rest; let it settle before
      // each scenario so tilting is guaranteed to wake and move it.
      _stepFor(harness.simulation, Tilt.flat, _settleTime);
    });

    tearDown(() {
      harness.simulation.dispose();
    });

    test('tilt right moves the marble toward +X', () {
      final startX = harness.simulation.marble.position.x;

      _stepFor(harness.simulation, Tilt(x: _rollTilt, y: 0), _rollTime);

      expect(harness.simulation.marble.position.x, greaterThan(startX));
    });

    test('tilt forward moves the marble toward -Z', () {
      final startZ = harness.simulation.marble.position.z;

      _stepFor(harness.simulation, Tilt(x: 0, y: _rollTilt), _rollTime);

      expect(harness.simulation.marble.position.z, lessThan(startZ));
    });

    test('a resting marble on a flat board stays at rest', () {
      final start = harness.simulation.marble.position.clone();

      _stepFor(harness.simulation, Tilt.flat, _rollTime);

      final moved = harness.simulation.marble.position.distanceTo(start);
      expect(moved, lessThan(0.05));
    });

    group('wall collisions', () {
      setUp(() {
        harness.simulation.load(_wallLevel());
        _stepFor(harness.simulation, Tilt.flat, _settleTime);
      });

      test('a wall stops the marble', () {
        final restY = harness.simulation.marble.position.y;
        harness.handle.placeMarble(Vector3(_wallX - 2, restY, 0));
        harness.handle.setMarbleVelocity(Vector3(4, 0, 0));

        _stepFor(
          harness.simulation,
          Tilt.flat,
          const Duration(milliseconds: 500),
        );

        expect(harness.simulation.marble.position.x, lessThan(_wallX));
      });

      test(
        'a marble at maximum speed never passes through a one-cell wall',
        () {
          final restY = harness.simulation.marble.position.y;
          harness.handle.placeMarble(Vector3(_wallX - 2, restY, 0));
          harness.handle.setMarbleVelocity(Vector3(harness.maxSpeed, 0, 0));

          var remaining = const Duration(milliseconds: 300);
          while (remaining > Duration.zero) {
            final step = remaining < _frame ? remaining : _frame;
            harness.simulation.step(Tilt.flat, step);
            expect(harness.simulation.marble.position.x, lessThan(_wallX));
            remaining -= step;
          }
        },
      );
    });

    group('holes', () {
      setUp(() {
        harness.simulation.load(_holeLevel());
        _stepFor(harness.simulation, Tilt.flat, _settleTime);
      });

      test('entering a hole emits FellInHole with that hole', () async {
        final events = <SimulationEvent>[];
        final subscription = harness.simulation.events.listen(events.add);
        final restY = harness.simulation.marble.position.y;
        harness.handle.placeMarble(Vector3(_holeX - 2, restY, 0));
        harness.handle.setMarbleVelocity(Vector3(4, 0, 0));

        _stepFor(harness.simulation, Tilt.flat, _holeApproachTime);
        await pumpEventQueue();

        expect(
          events,
          contains(isA<FellInHole>().having((e) => e.hole, 'hole', _hole)),
        );
        expect(harness.simulation.marble.isActive, isFalse);
        await subscription.cancel();
      });

      test(
        'a marble resting at the edge of a hole cell does not fall in',
        () async {
          final events = <SimulationEvent>[];
          final subscription = harness.simulation.events.listen(events.add);
          final restY = harness.simulation.marble.position.y;
          harness.handle.placeMarble(Vector3(_holeX - 0.5, restY, 0));

          _stepFor(harness.simulation, Tilt.flat, _settleTime);
          await pumpEventQueue();

          expect(events, isNot(contains(isA<FellInHole>())));
          expect(harness.simulation.marble.isActive, isTrue);
          await subscription.cancel();
        },
      );

      test(
        'respawn() returns the marble to the start and makes it active',
        () async {
          final restY = harness.simulation.marble.position.y;
          harness.handle.placeMarble(Vector3(_holeX - 2, restY, 0));
          harness.handle.setMarbleVelocity(Vector3(4, 0, 0));
          _stepFor(harness.simulation, Tilt.flat, _holeApproachTime);
          await pumpEventQueue();
          expect(harness.simulation.marble.isActive, isFalse);

          harness.simulation.respawn();

          expect(harness.simulation.marble.isActive, isTrue);
          expect(harness.simulation.marble.position.x, closeTo(0, 0.01));
          expect(harness.simulation.marble.position.z, closeTo(0, 0.01));

          // The respawned marble is dynamic again: tilting should move it.
          final startX = harness.simulation.marble.position.x;
          _stepFor(harness.simulation, Tilt(x: _rollTilt, y: 0), _rollTime);
          expect(harness.simulation.marble.position.x, greaterThan(startX));
        },
      );
    });

    test('a marble outside the board emits LeftBoard', () async {
      final events = <SimulationEvent>[];
      final subscription = harness.simulation.events.listen(events.add);
      final restY = harness.simulation.marble.position.y;
      harness.handle.placeMarble(Vector3(50, restY, 0));

      _stepFor(harness.simulation, Tilt.flat, _frame);
      await pumpEventQueue();

      expect(events, contains(isA<LeftBoard>()));
      expect(harness.simulation.marble.isActive, isFalse);
      await subscription.cancel();
    });

    test('marble speed never exceeds the maximum', () {
      harness.handle.setMarbleVelocity(Vector3(harness.maxSpeed * 3, 0, 0));

      harness.simulation.step(Tilt.flat, _frame);

      expect(
        harness.simulation.marble.velocity.length,
        lessThanOrEqualTo(harness.maxSpeed + 1e-3),
      );
    });
  });
}
