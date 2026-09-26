import 'package:meta/meta.dart';

/// The timing and easing for the marble's sink-into-a-hole animation:
/// it scales to zero and translates downward over [duration].
///
/// Kept as a pure class, separate from the 3D view that plays it, since
/// Flutter GPU does not render in widget tests, so this is what a unit test
/// can exercise instead.
@immutable
class MarbleSinkAnimation {
  /// Creates a sink animation with the given [duration] and [depth].
  const new({
    this.duration = const Duration(milliseconds: 500),
    this.depth = 0.5,
  });

  /// How long the animation takes to complete.
  final Duration duration;

  /// How far, in world units, the marble sinks over the course of the
  /// animation.
  final double depth;

  /// Whether the animation has finished by [elapsed] (time since it
  /// started).
  bool isCompleteAt(Duration elapsed) => elapsed >= duration;

  /// The animation's eased progress in `[0, 1]` at [elapsed]: 0 at the
  /// start, 1 once complete. Eases in, so the marble accelerates into the
  /// hole rather than sinking at a constant rate.
  double progressAt(Duration elapsed) {
    if (duration <= Duration.zero) return 1;
    final linear = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    return linear * linear;
  }

  /// The marble's uniform scale factor at [elapsed]: 1 at the start, 0 once
  /// complete.
  double scaleAt(Duration elapsed) => 1 - progressAt(elapsed);

  /// How far the marble should have sunk, in world units, at [elapsed].
  double sinkOffsetAt(Duration elapsed) => progressAt(elapsed) * depth;
}
