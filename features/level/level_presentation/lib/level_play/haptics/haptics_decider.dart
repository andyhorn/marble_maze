import 'package:meta/meta.dart';
import 'package:simulation_domain/simulation_domain.dart';

/// The strength of a haptic tap [HapticsDecider] recommends, or none.
enum HapticImpact {
  /// No haptic feedback for this event.
  none,

  /// A light tap, for a hard wall hit.
  light,

  /// A stronger tap, for falling into a hole or leaving the board.
  medium,
}

/// Decides which [HapticImpact] a [SimulationEvent] deserves, kept as a pure
/// class so it can be unit tested without `HapticFeedback` (which has no
/// effect in tests). The 3D view calls [decide] from its simulation-event
/// listener and forwards a non-[HapticImpact.none] result to
/// `HapticFeedback`.
@immutable
class HapticsDecider {
  /// Creates a haptics decider with the given tuning.
  const new({
    this.wallHitMinSpeed = 3,
    this.wallHitDebounce = const Duration(milliseconds: 150),
  });

  /// The minimum [HitWall] speed, in units per second, for a light impact.
  /// Below this, the marble only grazed the wall.
  final double wallHitMinSpeed;

  /// The minimum time since the last wall-hit impact before another one is
  /// allowed, so a marble scraping along a wall does not buzz repeatedly.
  final Duration wallHitDebounce;

  /// The impact for [event], given [elapsed] (the frame clock's current
  /// time) and [lastWallHitImpactElapsed] (when a wall-hit impact was last
  /// produced, or null if none has been yet).
  HapticImpact decide(
    SimulationEvent event,
    Duration elapsed, {
    Duration? lastWallHitImpactElapsed,
  }) {
    switch (event) {
      case HitWall(:final speed):
        if (speed < wallHitMinSpeed) return HapticImpact.none;
        final last = lastWallHitImpactElapsed;
        if (last != null && elapsed - last < wallHitDebounce) {
          return HapticImpact.none;
        }
        return HapticImpact.light;
      case FellInHole() || LeftBoard():
        return HapticImpact.medium;
      case ReachedExit():
        return HapticImpact.none;
    }
  }
}
