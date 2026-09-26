import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';

/// Something that happened to the marble during a simulation step.
@immutable
sealed class SimulationEvent {
  const new();
}

/// The marble fell into [hole].
class FellInHole extends SimulationEvent {
  /// Creates a fell-in-hole event for [hole].
  const new(this.hole);

  /// The hole the marble fell into.
  final GridPoint hole;
}

/// The marble left the board's bounds, dropped below the floor, or reached
/// a non-finite position. Treated like a hole fall.
class LeftBoard extends SimulationEvent {
  /// Creates a left-board event.
  const new();
}

/// The marble reached the level's exit.
class ReachedExit extends SimulationEvent {
  /// Creates a reached-exit event.
  const new();
}

/// The marble hit a wall at [speed] (units per second), above the
/// threshold for a haptic response.
class HitWall extends SimulationEvent {
  /// Creates a hit-wall event at [speed].
  const new(this.speed);

  /// The marble's speed at the moment of impact.
  final double speed;
}
