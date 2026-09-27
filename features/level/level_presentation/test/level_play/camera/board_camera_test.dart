import 'dart:ui' as ui;

import 'package:flutter_scene/scene.dart' show PerspectiveCamera;
import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Builds a real `PerspectiveCamera` from [pose], the same type
/// `BoardSceneView` renders with, so these tests check the pose against the
/// engine's own view/projection maths rather than re-deriving it.
PerspectiveCamera _camera(BoardCameraPose pose, {required double fovRadiansY}) {
  return PerspectiveCamera(
    fovRadiansY: fovRadiansY,
    position: pose.position,
    target: pose.target,
    up: pose.up,
  );
}

const _viewSize = ui.Size(390, 844);

void main() {
  group('BoardCamera', () {
    const camera = BoardCamera();
    final focusOrigin = vm.Vector2.zero();

    group('orientation', () {
      test('screen right is world +X and screen up is world +Z', () {
        const boardWidth = 9.0;
        const boardHeight = 16.0;
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: _viewSize.width / _viewSize.height,
          focus: focusOrigin,
        );
        final engineCamera = _camera(pose, fovRadiansY: camera.fovRadiansY);

        final center = engineCamera.worldToScreen(pose.target, _viewSize)!;
        final right = engineCamera.worldToScreen(
          pose.target + vm.Vector3(1, 0, 0),
          _viewSize,
        )!;
        final up = engineCamera.worldToScreen(
          pose.target + vm.Vector3(0, 0, 1),
          _viewSize,
        )!;

        expect(right.dx, greaterThan(center.dx));
        expect(up.dy, lessThan(center.dy));
      });
    });

    group('visibleSizeAtWallTop', () {
      const aspectRatio = 9 / 16;

      test('a tall board is width-limited: equal in width, narrower in '
          'height', () {
        const boardWidth = 9.0;
        const boardHeight = 40.0;

        final visible = camera.visibleSizeAtWallTop(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(visible.width, closeTo(boardWidth, 1e-9));
        expect(visible.height, lessThanOrEqualTo(boardHeight));
      });

      test('a wide board is height-limited: equal in height, narrower in '
          'width', () {
        const boardWidth = 40.0;
        const boardHeight = 9.0;

        final visible = camera.visibleSizeAtWallTop(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(visible.height, closeTo(boardHeight, 1e-9));
        expect(visible.width, lessThanOrEqualTo(boardWidth));
      });

      test('a board matching the viewport aspect ratio fits exactly in '
          'both axes', () {
        const boardHeight = 16.0;
        const boardWidth = boardHeight * aspectRatio;

        final visible = camera.visibleSizeAtWallTop(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(visible.width, closeTo(boardWidth, 1e-9));
        expect(visible.height, closeTo(boardHeight, 1e-9));
      });

      test('the visible rectangle never exceeds the board in either axis, '
          'even at a non-dyadic device aspect ratio', () {
        const deviceAspectRatio = 390 / 844;
        for (final size in [
          (width: 9.0, height: 40.0),
          (width: 40.0, height: 9.0),
          (width: 9.0, height: 9.0 / deviceAspectRatio),
        ]) {
          final visible = camera.visibleSizeAtWallTop(
            boardWidth: size.width,
            boardHeight: size.height,
            viewportAspectRatio: deviceAspectRatio,
          );

          expect(visible.width, lessThanOrEqualTo(size.width + 1e-9));
          expect(visible.height, lessThanOrEqualTo(size.height + 1e-9));
        }
      });
    });

    group('cameraHeightFor', () {
      test('a taller visible extent needs a higher camera', () {
        final shortHeight = camera.cameraHeightFor(5);
        final tallHeight = camera.cameraHeightFor(20);

        expect(tallHeight, greaterThan(shortHeight));
      });

      test('matches the trigonometric fit at the wall-top plane', () {
        const visibleHeight = 8.0;
        final height = camera.cameraHeightFor(visibleHeight);
        final heightAboveWallTop = height - camera.wallTopHeight;

        expect(
          heightAboveWallTop * 2 * (visibleHeight / 2 / heightAboveWallTop),
          closeTo(visibleHeight, 1e-9),
        );
      });
    });

    group('focusFor', () {
      const aspectRatio = 9 / 16;

      test('a board exactly matching the viewport gives focus (0, 0)', () {
        const boardHeight = 16.0;
        const boardWidth = boardHeight * aspectRatio;

        final focus = camera.focusFor(
          marbleX: 3,
          marbleZ: -4,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(focus.x, closeTo(0, 1e-9));
        expect(focus.y, closeTo(0, 1e-9));
      });

      test('clamps a marble beyond a tall board corner to keep the visible '
          'rectangle inside the board', () {
        const boardWidth = 9.0;
        const boardHeight = 40.0;

        final focus = camera.focusFor(
          marbleX: 1000,
          marbleZ: 1000,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final visible = camera.visibleSizeAtWallTop(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(focus.x + visible.width / 2, lessThanOrEqualTo(boardWidth / 2));
        expect(
          focus.x - visible.width / 2,
          greaterThanOrEqualTo(-boardWidth / 2),
        );
        expect(
          focus.y + visible.height / 2,
          lessThanOrEqualTo(boardHeight / 2 + 1e-9),
        );
        expect(
          focus.y - visible.height / 2,
          greaterThanOrEqualTo(-boardHeight / 2 - 1e-9),
        );
      });

      test('clamps a marble beyond a wide board corner', () {
        const boardWidth = 40.0;
        const boardHeight = 9.0;

        final focus = camera.focusFor(
          marbleX: -1000,
          marbleZ: -1000,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final visible = camera.visibleSizeAtWallTop(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(
          focus.x - visible.width / 2,
          greaterThanOrEqualTo(-boardWidth / 2),
        );
        expect(
          focus.y - visible.height / 2,
          greaterThanOrEqualTo(-boardHeight / 2 - 1e-9),
        );
      });

      test('does not throw at an exact-match board on a non-dyadic device '
          'aspect ratio', () {
        const deviceAspectRatio = 390 / 844;
        const boardHeight = 16.0;
        const boardWidth = boardHeight * deviceAspectRatio;

        expect(
          () => camera.focusFor(
            marbleX: 1000,
            marbleZ: -1000,
            boardWidth: boardWidth,
            boardHeight: boardHeight,
            viewportAspectRatio: deviceAspectRatio,
          ),
          returnsNormally,
        );
      });
    });

    group('no background ever visible', () {
      const aspectRatio = 9 / 16;

      void expectBoardFillsScreen({
        required double boardWidth,
        required double boardHeight,
        required double marbleX,
        required double marbleZ,
      }) {
        final focus = camera.focusFor(
          marbleX: marbleX,
          marbleZ: marbleZ,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
          focus: focus,
        );
        final engineCamera = _camera(pose, fovRadiansY: camera.fovRadiansY);

        // The focus is always clamped so a board corner is never nearer to
        // it than the corresponding visible-rectangle edge; so each wall-top
        // corner's screen projection must land at or beyond the matching
        // screen edge, never strictly inside it (which would expose
        // background beyond the board).
        for (final x in [-boardWidth / 2, boardWidth / 2]) {
          for (final z in [-boardHeight / 2, boardHeight / 2]) {
            final corner = vm.Vector3(x, camera.wallTopHeight, z);
            final screen = engineCamera.worldToScreen(corner, _viewSize)!;
            if (x < 0) {
              expect(screen.dx, lessThanOrEqualTo(1e-6));
            } else {
              expect(screen.dx, greaterThanOrEqualTo(_viewSize.width - 1e-6));
            }
            // World +Z is screen up, so the top-of-screen (dy near 0)
            // corresponds to the far (+Z) board edge.
            if (z < 0) {
              expect(screen.dy, greaterThanOrEqualTo(_viewSize.height - 1e-6));
            } else {
              expect(screen.dy, lessThanOrEqualTo(1e-6));
            }
          }
        }
      }

      for (final board in [
        (width: 9.0, height: 40.0),
        (width: 40.0, height: 9.0),
        (width: 16.0 * aspectRatio, height: 16.0),
      ]) {
        for (final marble in [
          (x: 0.0, z: 0.0),
          (x: board.width / 2, z: board.height / 2),
          (x: -board.width / 2, z: -board.height / 2),
          (x: 1000.0, z: 1000.0),
        ]) {
          test(
            'board ${board.width}x${board.height}, marble at '
            '(${marble.x}, ${marble.z})',
            () => expectBoardFillsScreen(
              boardWidth: board.width,
              boardHeight: board.height,
              marbleX: marble.x,
              marbleZ: marble.z,
            ),
          );
        }
      }
    });

    group('smoothing', () {
      test('smoothing converges to the same place at 60 fps and 120 fps', () {
        const totalDuration = Duration(milliseconds: 500);
        const frame60 = Duration(milliseconds: 16, microseconds: 667);
        const frame120 = Duration(milliseconds: 8, microseconds: 333);

        var at60 = 0.0;
        var elapsed60 = Duration.zero;
        while (elapsed60 < totalDuration) {
          at60 = camera.smoothTowards(at60, 10, frame60);
          elapsed60 += frame60;
        }

        var at120 = 0.0;
        var elapsed120 = Duration.zero;
        while (elapsed120 < totalDuration) {
          at120 = camera.smoothTowards(at120, 10, frame120);
          elapsed120 += frame120;
        }

        expect(at60, closeTo(at120, 0.05));
      });

      test('smoothing never overshoots the target', () {
        final result = camera.smoothTowards(0, 10, const Duration(seconds: 10));

        expect(result, closeTo(10, 1e-6));
      });
    });
  });
}
