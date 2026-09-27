import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The pure maths behind the level play scene's directional light: a travel
/// direction that shifts with the board's tilt, so shadows read as though a
/// world light stays fixed in place while the phone (and the board with it)
/// tilts beneath it.
///
/// Kept separate from `BoardSceneView` (which owns the actual
/// `DirectionalLight`) so a unit test can exercise it without the engine.
@immutable
class BoardLight {
  /// Creates a board light plan with the given tuning.
  const new({
    this.baseX = -0.3,
    this.baseY = -1,
    this.baseZ = -0.35,
    this.gain = 3,
    this.smoothingRate = 8,
  });

  /// The light's travel direction's X component at [Tilt.flat], roughly 25°
  /// off vertical.
  final double baseX;

  /// The light's travel direction's Y component at [Tilt.flat].
  final double baseY;

  /// The light's travel direction's Z component at [Tilt.flat].
  final double baseZ;

  /// How strongly the current tilt shifts the light's horizontal travel
  /// components, so a tilted board reads as a fixed world light casting a
  /// longer, downhill-shifted shadow.
  final double gain;

  /// The exponential smoothing rate (per second) the light's tilt follows
  /// the input tilt at. The physics uses the input tilt directly, but it
  /// arrives in discrete sensor-rate steps that would make the shadows
  /// visibly jump if the light used it unsmoothed.
  final double smoothingRate;

  /// The light's travel direction (from the light toward the scene) for
  /// [tilt]: [baseX]/[baseY]/[baseZ] at [Tilt.flat], shifted in X and Z
  /// toward the downhill direction as [tilt] increases. Need not be unit
  /// length; `DirectionalLight.direction` normalizes internally.
  vm.Vector3 directionFor(Tilt tilt) => vm.Vector3(
    baseX + gain * math.sin(tilt.x),
    baseY,
    baseZ + gain * math.sin(tilt.y),
  );

  /// Advances [current] toward [target] by [elapsed], using frame-rate
  /// independent exponential smoothing at [smoothingRate].
  Tilt smoothTowards(Tilt current, Tilt target, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final rate = 1 - math.exp(-smoothingRate * seconds);
    return Tilt(
      x: current.x + (target.x - current.x) * rate,
      y: current.y + (target.y - current.y) * rate,
    );
  }
}
