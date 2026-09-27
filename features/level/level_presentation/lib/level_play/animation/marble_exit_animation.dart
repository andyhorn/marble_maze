import 'package:meta/meta.dart';

/// The timing and easing for the marble's exit-cup settle animation on win:
/// it eases from its position at the moment of `ReachedExit` to the cup's
/// centre, sinking [depth] into it over [duration].
///
/// A sibling of `MarbleSinkAnimation`, kept as its own pure class rather than
/// a shared one since the two play at different moments (mid-level fall vs.
/// end-of-level win) and may need different tuning. Separate from the 3D
/// view that plays it for the same reason as `MarbleSinkAnimation`: Flutter
/// GPU does not render in widget tests, so this is what a unit test can
/// exercise instead.
@immutable
class MarbleExitAnimation {
  /// Creates an exit animation with the given [duration] and [depth].
  const new({
    this.duration = const Duration(milliseconds: 600),
    this.depth = 0.5,
  });

  /// How long the animation takes to complete.
  final Duration duration;

  /// How far, in world units, the marble sinks into the exit cup over the
  /// course of the animation. Matches the exit cup's visual depth
  /// (`BoardSceneView`'s cup geometry), so the marble comes to rest exactly
  /// at the cup's bottom instead of floating above it or clipping through.
  final double depth;

  /// Whether the animation has finished by [elapsed] (time since it
  /// started).
  bool isCompleteAt(Duration elapsed) => elapsed >= duration;

  /// The animation's eased progress in `[0, 1]` at [elapsed]: 0 at the
  /// start, 1 once complete. Eases out, so the marble settles into the cup
  /// rather than snapping to a stop.
  double progressAt(Duration elapsed) {
    if (duration <= Duration.zero) return 1;
    final linear = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    return 1 - (1 - linear) * (1 - linear);
  }

  /// How far the marble should have sunk, in world units, at [elapsed].
  double sinkOffsetAt(Duration elapsed) => progressAt(elapsed) * depth;
}
