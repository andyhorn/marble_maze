import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The pure maths behind the level play camera: a fixed pitch, distance
/// chosen to fit the board's width, and (on a board too tall to also fit
/// vertically) a Z target that follows the marble, smoothed frame-rate
/// independently.
///
/// Kept separate from `BoardSceneView` (which owns the actual
/// `PerspectiveCamera`) since Flutter GPU does not render in widget tests,
/// so this is what a unit test can exercise instead.
@immutable
class BoardCamera {
  /// Creates a board camera plan with the given tuning.
  const new({
    this.pitchRadians = 55 * math.pi / 180,
    this.fovRadiansY = 50 * math.pi / 180,
    this.margin = 1.15,
    this.followSmoothingRate = 6,
  });

  /// The camera's fixed downward pitch, in radians, from horizontal.
  final double pitchRadians;

  /// The camera's vertical field of view, in radians.
  final double fovRadiansY;

  /// A multiplier above `1` on the fitting distance, for a little padding
  /// around the board.
  final double margin;

  /// The exponential smoothing rate (per second) the Z target follows the
  /// marble at. Higher values catch up faster.
  final double followSmoothingRate;

  /// The camera distance from the board center that fits [boardWidth]
  /// horizontally in a viewport of [viewportAspectRatio] (width / height).
  double distanceToFit(double boardWidth, double viewportAspectRatio) {
    final horizontalFov =
        2 * math.atan(math.tan(fovRadiansY / 2) * viewportAspectRatio);
    return (boardWidth / 2) / math.tan(horizontalFov / 2) * margin;
  }

  /// The board depth (world-space Z extent) visible on the ground plane at
  /// [distance], given the fixed [pitchRadians].
  double visibleDepthAt(double distance) =>
      2 * distance * math.tan(fovRadiansY / 2) / math.sin(pitchRadians);

  /// Whether a board of [boardWidth] by [boardHeight] fits entirely on
  /// screen at the distance that fits its width, in a viewport of
  /// [viewportAspectRatio].
  bool fitsOnScreen({
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
  }) {
    final distance = distanceToFit(boardWidth, viewportAspectRatio);
    return visibleDepthAt(distance) >= boardHeight;
  }

  /// The camera's Z target: `0` (the board's center) if the board fits on
  /// screen, otherwise [marbleZ] clamped so the visible depth never runs
  /// past the board's near/far edges.
  double targetZFor({
    required double marbleZ,
    required double boardHeight,
    required double viewportAspectRatio,
    required double boardWidth,
  }) {
    final distance = distanceToFit(boardWidth, viewportAspectRatio);
    final visibleHalfDepth = visibleDepthAt(distance) / 2;
    final boardHalfDepth = boardHeight / 2;
    final clampRange = boardHalfDepth - visibleHalfDepth;
    if (clampRange <= 0) return 0;
    return marbleZ.clamp(-clampRange, clampRange);
  }

  /// Advances [current] toward [target] by [elapsed], using frame-rate
  /// independent exponential smoothing.
  double smoothTowards(double current, double target, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final rate = 1 - math.exp(-followSmoothingRate * seconds);
    return current + (target - current) * rate;
  }
}
