import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:simulation_domain/simulation_domain.dart' show kWallHeight;
import 'package:vector_math/vector_math.dart' as vm;

/// A camera position and look-at target in world space.
@immutable
class BoardCameraPose {
  /// Creates a pose.
  const new({required this.position, required this.target});

  /// The camera's world-space eye point.
  final vm.Vector3 position;

  /// The world-space point the camera looks at.
  final vm.Vector3 target;
}

/// The pure maths behind the level play camera: a fixed pitch and a height
/// chosen to fit the board's width (including its outer wall border) at the
/// near, bottom-of-screen edge of the view, where perspective leaves the
/// least room; and, on a board too tall to also fit vertically, a Z target
/// that follows the marble, smoothed frame-rate independently and clamped so
/// the view never runs past the board's ends. A board that does fit
/// vertically is instead screen-centered, which (under perspective, with the
/// near and far view spans unequal) is not simply Z target `0`.
///
/// Kept separate from `BoardSceneView` (which owns the actual
/// `PerspectiveCamera`) since Flutter GPU does not render in widget tests,
/// so this is what a unit test can exercise instead.
@immutable
class BoardCamera {
  /// Creates a board camera plan with the given tuning.
  const new({
    this.pitchRadians = 60 * math.pi / 180,
    this.fovRadiansY = 50 * math.pi / 180,
    this.margin = 1,
    this.followSmoothingRate = 6,
    this.wallTopHeight = kWallHeight,
  });

  /// The camera's fixed downward pitch, in radians, from horizontal. Kept in
  /// the 55–70° range: steep enough to read as looking down at a board,
  /// shallow enough that walls and their shadows are still visible in
  /// profile rather than foreshortened flat.
  final double pitchRadians;

  /// The camera's vertical field of view, in radians.
  final double fovRadiansY;

  /// A multiplier on the width fit: `1` (the default) spans the board's
  /// full width, including its outer wall border, exactly to the screen
  /// edge with nothing cropped; a value above `1` pulls the camera back for
  /// a little extra padding.
  final double margin;

  /// The exponential smoothing rate (per second) the Z target follows the
  /// marble at. Higher values catch up faster.
  final double followSmoothingRate;

  /// The height, in world units, of the outer wall border's top edge above
  /// the floor. The border wall is the tallest, nearest-to-camera geometry
  /// at the board's outer edge, so it (not the floor) is what must clear the
  /// screen edge for nothing to be cropped.
  final double wallTopHeight;

  double get _halfFovY => fovRadiansY / 2;

  double _halfFovX(double aspectRatio) =>
      math.atan(math.tan(_halfFovY) * aspectRatio);

  /// The camera's forward horizontal offset from its look-at target, for a
  /// camera at [cameraHeight] and the fixed [pitchRadians].
  double _horizontalOffset(double cameraHeight) =>
      cameraHeight / math.tan(pitchRadians);

  /// The camera height (world Y, above the floor plane) at which the near
  /// (bottom-of-screen) scanline's horizontal reach, at [wallTopHeight],
  /// exactly spans half of [boardWidth] (times [margin]).
  ///
  /// Perspective narrows what's visible at the far edge and widens it at the
  /// near edge, so fitting at the near edge (rather than at the board's
  /// center distance) is what keeps the whole width on screen everywhere.
  double cameraHeightToFitWidth(double boardWidth, double aspectRatio) {
    final halfFovX = _halfFovX(aspectRatio);
    final halfWidth = boardWidth / 2 * margin;
    final steepness =
        math.sin(pitchRadians) + math.tan(_halfFovY) * math.cos(pitchRadians);
    return wallTopHeight + halfWidth * steepness / math.tan(halfFovX);
  }

  /// The Z offset, from the camera's look-at target, of the point where a
  /// ray tilted [verticalAngleOffset] from the view's center (up positive)
  /// crosses the horizontal plane at [planeHeight], for a camera at
  /// [cameraHeight] above that same reference (`y = 0`).
  double _zOffsetAtPlane(
    double verticalAngleOffset,
    double cameraHeight,
    double planeHeight,
  ) {
    final tanPhi = math.tan(verticalAngleOffset);
    final worldY = tanPhi * math.cos(pitchRadians) - math.sin(pitchRadians);
    final worldZ = tanPhi * math.sin(pitchRadians) + math.cos(pitchRadians);
    final t = (planeHeight - cameraHeight) / worldY;
    return t * worldZ - _horizontalOffset(cameraHeight);
  }

  /// How far past the look-at target, in world Z, the far (top-of-screen)
  /// edge of the view's floor (`y = 0`) reach extends, for a camera at
  /// [cameraHeight].
  double farSpan(double cameraHeight) =>
      _zOffsetAtPlane(_halfFovY, cameraHeight, 0);

  /// How far short of the look-at target, in world Z, the near
  /// (bottom-of-screen) edge of the view's floor (`y = 0`) reach falls, for
  /// a camera at [cameraHeight]. Always less than [farSpan] at the same
  /// height: the near edge, being closer to the camera, is reached by a
  /// more steeply downward ray and so covers less ground.
  double nearSpan(double cameraHeight) =>
      -_zOffsetAtPlane(-_halfFovY, cameraHeight, 0);

  /// The Z at which the near (bottom-of-screen) scanline crosses the outer
  /// wall's top ([wallTopHeight]), for a camera at [cameraHeight] looking at
  /// Z `0`: the point [cameraHeightToFitWidth] actually fits the board's
  /// width at, closer to the camera than where that same scanline crosses
  /// the floor ([nearSpan]).
  double nearWallTopZ(double cameraHeight) =>
      _zOffsetAtPlane(-_halfFovY, cameraHeight, wallTopHeight);

  /// Whether a board of [boardWidth] by [boardHeight] fits entirely on
  /// screen at the height that fits its width, in a viewport of
  /// [viewportAspectRatio].
  bool fitsOnScreen({
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
  }) {
    final cameraHeight = cameraHeightToFitWidth(
      boardWidth,
      viewportAspectRatio,
    );
    return nearSpan(cameraHeight) + farSpan(cameraHeight) >= boardHeight;
  }

  /// The look-at Z target that screen-centers a board [boardHeight] deep, at
  /// a camera height of [cameraHeight].
  ///
  /// The near and far view spans are unequal under perspective, so
  /// centering is not target `0`: it's the target whose near and far board
  /// edges subtend equal angles from the view's center ray, found by
  /// bisection since that condition has no closed form here. Equivalently,
  /// the two edges' depression angles from horizontal (at the camera's
  /// fixed height) sum to twice [pitchRadians].
  double _centeredTargetZ(double boardHeight, double cameraHeight) {
    final halfBoard = boardHeight / 2;
    double angleSumAt(double nearGroundDistance) =>
        math.atan(cameraHeight / nearGroundDistance) +
        math.atan(cameraHeight / (nearGroundDistance + boardHeight));

    var low = 1e-9;
    var high = math.max(cameraHeight, boardHeight) * 1e4 + 1;
    for (var i = 0; i < 60; i++) {
      final mid = (low + high) / 2;
      if (angleSumAt(mid) > 2 * pitchRadians) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final nearGroundDistance = (low + high) / 2;
    final footpointZ = -halfBoard - nearGroundDistance;
    return footpointZ + _horizontalOffset(cameraHeight);
  }

  /// The camera's Z look-at target for a board [boardWidth] by
  /// [boardHeight]: screen-centered on the board if it fits on screen
  /// (see [_centeredTargetZ]), otherwise [marbleZ] clamped so the visible
  /// view never runs past the board's near/far edges.
  double targetZFor({
    required double marbleZ,
    required double boardWidth,
    required double boardHeight,
    required double viewportAspectRatio,
  }) {
    final cameraHeight = cameraHeightToFitWidth(
      boardWidth,
      viewportAspectRatio,
    );
    if (fitsOnScreen(
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      viewportAspectRatio: viewportAspectRatio,
    )) {
      return _centeredTargetZ(boardHeight, cameraHeight);
    }
    final halfBoard = boardHeight / 2;
    final lowClamp = -halfBoard + nearSpan(cameraHeight);
    final highClamp = halfBoard - farSpan(cameraHeight);
    return marbleZ.clamp(lowClamp, highClamp);
  }

  /// Advances [current] toward [target] by [elapsed], using frame-rate
  /// independent exponential smoothing.
  double smoothTowards(double current, double target, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final rate = 1 - math.exp(-followSmoothingRate * seconds);
    return current + (target - current) * rate;
  }

  /// The camera position and look-at target for a board [boardWidth] wide,
  /// in a viewport of [viewportAspectRatio], with its Z look-at at
  /// [cameraZ] (from [targetZFor], typically smoothed by [smoothTowards]).
  BoardCameraPose poseFor({
    required double boardWidth,
    required double viewportAspectRatio,
    required double cameraZ,
  }) {
    final cameraHeight = cameraHeightToFitWidth(
      boardWidth,
      viewportAspectRatio,
    );
    final horizontalOffset = _horizontalOffset(cameraHeight);
    return BoardCameraPose(
      position: vm.Vector3(0, cameraHeight, cameraZ - horizontalOffset),
      target: vm.Vector3(0, 0, cameraZ),
    );
  }
}
