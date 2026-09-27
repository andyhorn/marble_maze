import 'package:simulation_domain/simulation_domain.dart';

/// Tuning constants for `Box3dMarbleSimulation`.
class Box3dMarbleSimulationConfig {
  /// Creates a config. See each field for its meaning.
  const new({
    this.gravityMagnitude = 9.81 * 13,
    this.marbleRadius = kMarbleRadius,
    this.wallHeight = kWallHeight,
    this.wallThickness = 0.2,
    this.floorThickness = 0.5,
    this.holeTriggerRadius = kHoleRadius,
    this.exitTriggerRadius = kExitRadius,
    this.linearDamping = 3.5,
    this.angularDamping = 0.05,
    this.fixedTimestepSeconds = 1 / 120,
    this.maxStepElapsed = const Duration(milliseconds: 100),
    this.maxSpeed = 12,
    this.hitWallMinSpeed = 0.5,
  });

  /// The default tuning.
  static const Box3dMarbleSimulationConfig standard =
      Box3dMarbleSimulationConfig();

  /// Gravity's magnitude, in units per second squared, at zero tilt.
  ///
  /// `9.81 * 13`: tuned jointly with [linearDamping], not a real-world
  /// value. The marble is a rolling sphere, so its terminal speed at a given
  /// tilt is roughly `gravityMagnitude * sin(tilt) / linearDamping`, and the
  /// ratio between the 15° and 5° terminal speeds is fixed by that formula
  /// (`sin(15°) / sin(5°) ≈ 3`). Capping the 15° terminal speed at 10 u/s
  /// (so the marble stays controllable at max tilt) therefore caps the 5°
  /// terminal speed too, which in turn caps how fast the marble can spin up
  /// from rest. Reaching a responsive-feeling 2 u/s within 0.5s of a 5°
  /// tilt needs gravity around this magnitude; a true-to-scale value
  /// (~9.81 * 6, given a 1.5cm real cell per grid unit) is too weak to hit
  /// that target under any linearDamping that also keeps top speed in
  /// range.
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
  ///
  /// Tuned jointly with [gravityMagnitude]: this is what bounds the
  /// marble's terminal speed at full tilt (see [gravityMagnitude]'s doc),
  /// and its reciprocal sets roughly how fast the marble spins up from rest
  /// or reverses direction.
  final double linearDamping;

  /// Angular damping applied to the marble.
  ///
  /// Left low: once rolling, spin damping acts on the marble's linear speed
  /// like extra [linearDamping] at roughly 0.4x weight, so [linearDamping]
  /// is the primary knob for both terminal speed and how fast the marble
  /// changes direction.
  final double angularDamping;

  /// The internal fixed physics timestep, in seconds.
  final double fixedTimestepSeconds;

  /// The maximum wall-clock time a single `step` call advances, so a
  /// resume after a stall does not dump a burst of steps.
  final Duration maxStepElapsed;

  /// The marble's maximum speed, in units per second. Clamped every fixed
  /// step.
  final double maxSpeed;

  /// The minimum approach speed, in units per second, for a wall contact to
  /// emit [HitWall]. Below this, resting or slow-rolling contact against a
  /// wall (or the floor) never emits an event.
  final double hitWallMinSpeed;
}
