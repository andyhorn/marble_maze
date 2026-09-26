import 'package:level_domain/level_domain.dart';
import 'package:simulation_domain/src/marble_state.dart';
import 'package:simulation_domain/src/simulation_event.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// A physics backend that rolls a marble around a [Level].
///
/// Implementations advance physics on a fixed internal timestep; [step]
/// receives wall-clock elapsed time and keeps the remainder for the next
/// call. Gravity tilts, not the board: the board itself never rotates in
/// physics.
abstract interface class IMarbleSimulation {
  /// Loads [level], placing the marble at its start cell.
  void load(Level level);

  /// Advances the simulation by [elapsed] wall-clock time under [tilt].
  ///
  /// [elapsed] is clamped to 0.1 seconds per call so a resume after a stall
  /// does not dump a burst of steps.
  void step(Tilt tilt, Duration elapsed);

  /// Returns the marble to the level's start cell, at rest.
  void respawn();

  /// The marble's current state.
  MarbleState get marble;

  /// Events produced by [step]: falling in a hole, leaving the board,
  /// reaching the exit, or hitting a wall.
  Stream<SimulationEvent> get events;

  /// Releases the resources this simulation holds.
  void dispose();
}
