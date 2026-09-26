import 'package:simulation_domain/simulation_domain.dart';

/// Tuning constants for `Box3dMarbleSimulation`.
class Box3dMarbleSimulationConfig {
  /// Creates a config. See each field for its meaning.
  const new({
    this.gravityMagnitude = 9.81,
    this.marbleRadius = kMarbleRadius,
    this.wallHeight = kWallHeight,
    this.wallThickness = 0.2,
    this.floorThickness = 0.5,
    this.holeTriggerRadius = kHoleRadius,
    this.exitTriggerRadius = kExitRadius,
    this.linearDamping = 0.3,
    this.angularDamping = 0.05,
    this.fixedTimestepSeconds = 1 / 120,
    this.maxStepElapsed = const Duration(milliseconds: 100),
    this.maxSpeed = 12,
  });

  /// The default tuning.
  static const Box3dMarbleSimulationConfig standard =
      Box3dMarbleSimulationConfig();

  /// Gravity's magnitude, in units per second squared, at zero tilt.
  final double gravityMagnitude;

  /// The marble's collision radius.
  final double marbleRadius;

  /// The height of wall colliders (interior walls and the outer border).
  final double wallHeight;

  /// The thickness of the outer border wall.
  final double wallThickness;

  /// The thickness of the floor collider.
  final double floorThickness;

  /// How close the marble's centre must come to a hole's centre to fall in.
  final double holeTriggerRadius;

  /// How close the marble's centre must come to the exit's centre to finish.
  final double exitTriggerRadius;

  /// Linear damping applied to the marble, approximating rolling
  /// resistance.
  final double linearDamping;

  /// Angular damping applied to the marble.
  final double angularDamping;

  /// The internal fixed physics timestep, in seconds.
  final double fixedTimestepSeconds;

  /// The maximum wall-clock time a single `step` call advances, so a
  /// resume after a stall does not dump a burst of steps.
  final Duration maxStepElapsed;

  /// The marble's maximum speed, in units per second. Clamped every fixed
  /// step.
  final double maxSpeed;
}
