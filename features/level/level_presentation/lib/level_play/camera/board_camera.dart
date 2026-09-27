import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:simulation_domain/simulation_domain.dart' show kWallHeight;
import 'package:vector_math/vector_math.dart' as vm;

/// A camera position, look-at target, and up vector in world space.
@immutable
class BoardCameraPose {
  /// Creates a pose.
  const new({required this.position, required this.target, required this.up});

  /// The camera's world-space eye point.
  final vm.Vector3 position;

  /// The world-space point the camera looks at.
  final vm.Vector3 target;

  /// The world-space "up" direction used to orient the camera around the
  /// view vector.
  final vm.Vector3 up;
}

/// The visible rectangle's width and height, in world units, at some
/// horizontal plane.
@immutable
class BoardCameraVisibleSize {
  /// Creates a visible size.
  const new({required this.width, required this.height});

  /// The visible rectangle's width.
  final double width;

  /// The visible rectangle's height.
  final double height;
}

/// The pure maths behind the level play camera: a straight top-down view,
/// cover-fit at the wall-top plane so the board (including its outer wall
/// border) always fills the screen in both directions with nothing beyond
/// it ever visible, and a focus point that follows the marble in X and Z,
/// smoothed frame-rate independently and clamped so the visible rectangle
/// never runs past the board's edges.
///
/// Kept separate from `BoardSceneView` (which owns the actual
/// `PerspectiveCamera`) since Flutter GPU does not render in widget tests,
/// so this is what a unit test can exercise instead.
@immutable
class BoardCamera {
  /// Creates a board camera plan with the given tuning.
  const new({
    this.fovRadiansY = 32 * math.pi / 180,
    this.followSmoothingRate = 6,
    this.wallTopHeight = kWallHeight,
  });

  /// The camera's vertical field of view, in radians.
  final double fovRadiansY;

  /// The exponential smoothing rate (per second) the focus follows the
  /// marble at. Higher values catch up faster.
  final double followSmoothingRate;

  /// The height, in world units, of the outer wall border's top edge above
  /// the floor. Cover-fitting at this plane (rather than the floor)
  /// guarantees every edge ray hits a wall top or the maze interior, never
  /// the void beyond the board.
  final double wallTopHeight;

  double get _halfFovY => fovRadiansY / 2;

  /// The visible rectangle at the wall-top plane for a board [boardWidth] by
  /// [boardHeight] in a viewport of [viewportAspectRatio]: the largest
  /// rectangle of that aspect ratio that fits entirely inside the board,
  /// i.e. never larger than the board in either axis and equal to it in (at
  /// least) one.
  BoardCameraVisibleSize visibleSizeAtWallTop({
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
  }) {
    final width = math.min(boardWidth, boardHeight * viewportAspectRatio);
    return BoardCameraVisibleSize(
      width: width,
      height: width / viewportAspectRatio,
    );
  }

  /// The camera height (world Y, above the floor plane) that fits
  /// [visibleHeight] world units of vertical extent, at [wallTopHeight],
  /// exactly within the vertical field of view.
  double cameraHeightFor(double visibleHeight) =>
      wallTopHeight + (visibleHeight / 2) / math.tan(_halfFovY);

  /// The camera's X/Z focus point for a board [boardWidth] by [boardHeight]
  /// in a viewport of [viewportAspectRatio]: the marble's position, clamped
  /// so the visible wall-top rectangle stays inside the board. The returned
  /// vector's `x` is world X and its `y` is world Z.
  vm.Vector2 focusFor({
    required double marbleX,
    required double marbleZ,
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
  }) {
    final visible = visibleSizeAtWallTop(
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      viewportAspectRatio: viewportAspectRatio,
    );
    final halfClampX = math.max(0, (boardWidth - visible.width) / 2).toDouble();
    final halfClampZ = math
        .max(0, (boardHeight - visible.height) / 2)
        .toDouble();
    return vm.Vector2(
      marbleX.clamp(-halfClampX, halfClampX),
      marbleZ.clamp(-halfClampZ, halfClampZ),
    );
  }

  /// Advances [current] toward [target] by [elapsed], using frame-rate
  /// independent exponential smoothing.
  double smoothTowards(double current, double target, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final rate = 1 - math.exp(-followSmoothingRate * seconds);
    return current + (target - current) * rate;
  }

  /// The camera position, look-at target, and up vector for a board
  /// [boardWidth] by [boardHeight], in a viewport of [viewportAspectRatio],
  /// looking straight down at [focus] (world X in `focus.x`, world Z in
  /// `focus.y`; from [focusFor], typically smoothed per axis by
  /// [smoothTowards]).
  BoardCameraPose poseFor({
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
    required vm.Vector2 focus,
  }) {
    final visible = visibleSizeAtWallTop(
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      viewportAspectRatio: viewportAspectRatio,
    );
    final cameraHeight = cameraHeightFor(visible.height);
    return BoardCameraPose(
      position: vm.Vector3(focus.x, cameraHeight, focus.y),
      target: vm.Vector3(focus.x, 0, focus.y),
      up: vm.Vector3(0, 0, 1),
    );
  }
}
