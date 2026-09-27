import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Builds a standard right-handed lookAt/perspective view-projection matrix
/// from [pose] and [fovRadiansY]/[aspectRatio], independent of
/// `BoardCamera`'s own trig, so these tests check its output geometrically
/// rather than re-deriving (and risking repeating a mistake in) its formula.
vm.Matrix4 _viewProjection(
  BoardCameraPose pose, {
  required double fovRadiansY,
  required double aspectRatio,
}) {
  final view = vm.makeViewMatrix(
    pose.position,
    pose.target,
    vm.Vector3(0, 1, 0),
  );
  final projection = vm.makePerspectiveMatrix(
    fovRadiansY,
    aspectRatio,
    0.1,
    1000,
  );
  return projection.multiplied(view);
}

/// The normalized device coordinates (x, y in `[-1, 1]` when on screen) of
/// [world] under [viewProjection].
vm.Vector2 _ndc(vm.Matrix4 viewProjection, vm.Vector3 world) {
  final clip = viewProjection.transform(
    vm.Vector4(world.x, world.y, world.z, 1),
  );
  return vm.Vector2(clip.x / clip.w, clip.y / clip.w);
}

void main() {
  group('BoardCamera', () {
    const aspectRatio = 9 / 16;

    group('width fit', () {
      // margin defaults to 1, an exact edge fit; a separate test covers
      // margin's padding.
      const camera = BoardCamera();
      const boardWidth = 9.0;
      const cameraZ = 0.0;

      test('the near, outer wall-top corners land exactly at the screen '
          'edge', () {
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: cameraZ,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: camera.fovRadiansY,
          aspectRatio: aspectRatio,
        );
        final nearZ = cameraZ + camera.nearWallTopZ(pose.position.y);

        final leftCorner = _ndc(
          viewProjection,
          vm.Vector3(-boardWidth / 2, camera.wallTopHeight, nearZ),
        );
        final rightCorner = _ndc(
          viewProjection,
          vm.Vector3(boardWidth / 2, camera.wallTopHeight, nearZ),
        );

        // Whether world +X maps to NDC +1 or -1 is this test matrix's own
        // (right-handed lookAt) convention, independent of the left-handed
        // convention `BoardSceneView`'s actual camera renders with; the
        // fit itself is what's under test, so check magnitude and that the
        // two corners land on opposite edges.
        expect(leftCorner.x.abs(), closeTo(1, 1e-6));
        expect(rightCorner.x.abs(), closeTo(1, 1e-6));
        expect(leftCorner.x, closeTo(-rightCorner.x, 1e-6));
      });

      test('margin above 1 pulls the fit comfortably inside the screen', () {
        const paddedCamera = BoardCamera(margin: 1.1);
        final pose = paddedCamera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: cameraZ,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: paddedCamera.fovRadiansY,
          aspectRatio: aspectRatio,
        );
        final nearZ = cameraZ + paddedCamera.nearWallTopZ(pose.position.y);

        final rightCorner = _ndc(
          viewProjection,
          vm.Vector3(boardWidth / 2, paddedCamera.wallTopHeight, nearZ),
        );

        expect(rightCorner.x.abs(), lessThan(1));
        expect(rightCorner.x.abs(), greaterThan(0.85));
      });

      test('no board corner at the wall-top height is cropped anywhere in '
          'the visible depth', () {
        final cameraHeight = camera.cameraHeightToFitWidth(
          boardWidth,
          aspectRatio,
        );
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: cameraZ,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: camera.fovRadiansY,
          aspectRatio: aspectRatio,
        );
        final nearZ = cameraZ - camera.nearSpan(cameraHeight);
        final farZ = cameraZ + camera.farSpan(cameraHeight);

        for (final z in [nearZ, (nearZ + farZ) / 2, farZ]) {
          final left = _ndc(
            viewProjection,
            vm.Vector3(-boardWidth / 2, camera.wallTopHeight, z),
          );
          final right = _ndc(
            viewProjection,
            vm.Vector3(boardWidth / 2, camera.wallTopHeight, z),
          );
          expect(left.x, greaterThanOrEqualTo(-1.0001));
          expect(right.x, lessThanOrEqualTo(1.0001));
        }
      });
    });

    group('vertical centering', () {
      const camera = BoardCamera();

      test('a small board fits and is screen-centered', () {
        const boardWidth = 9.0;
        const boardHeight = 9.0;

        expect(
          camera.fitsOnScreen(
            boardWidth: boardWidth,
            boardHeight: boardHeight,
            viewportAspectRatio: aspectRatio,
          ),
          isTrue,
        );

        final targetZ = camera.targetZFor(
          marbleZ: 3,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: targetZ,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: camera.fovRadiansY,
          aspectRatio: aspectRatio,
        );

        final near = _ndc(viewProjection, vm.Vector3(0, 0, -boardHeight / 2));
        final far = _ndc(viewProjection, vm.Vector3(0, 0, boardHeight / 2));

        expect(near.y, closeTo(-far.y, 1e-4));
      });

      test('the follow target is unaffected by marbleZ once centered', () {
        const boardWidth = 9.0;
        const boardHeight = 9.0;

        final targetNearStart = camera.targetZFor(
          marbleZ: -3,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final targetNearEnd = camera.targetZFor(
          marbleZ: 3,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(targetNearStart, targetNearEnd);
      });
    });

    group('following a tall board', () {
      const camera = BoardCamera();
      const boardWidth = 9.0;
      const boardHeight = 40.0;

      test('a tall board does not fit and the target follows the marble', () {
        expect(
          camera.fitsOnScreen(
            boardWidth: boardWidth,
            boardHeight: boardHeight,
            viewportAspectRatio: aspectRatio,
          ),
          isFalse,
        );

        // Comfortably inside the follow clamp range (unlike the near and
        // far spans, which are unequal under perspective, this Z is well
        // clear of either edge).
        const marbleZ = 1.0;
        final target = camera.targetZFor(
          marbleZ: marbleZ,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );

        expect(target, marbleZ);
      });

      test('the follow target is clamped so the far board edge never goes '
          'past the screen edge', () {
        final target = camera.targetZFor(
          marbleZ: 1000,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: target,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: camera.fovRadiansY,
          aspectRatio: aspectRatio,
        );

        final farBoardEdge = _ndc(
          viewProjection,
          vm.Vector3(0, 0, boardHeight / 2),
        );

        expect(farBoardEdge.y, closeTo(1, 1e-4));
        expect(target, lessThan(boardHeight / 2));
      });

      test('the follow target is clamped so the near board edge never goes '
          'past the screen edge', () {
        final target = camera.targetZFor(
          marbleZ: -1000,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        );
        final pose = camera.poseFor(
          boardWidth: boardWidth,
          viewportAspectRatio: aspectRatio,
          cameraZ: target,
        );
        final viewProjection = _viewProjection(
          pose,
          fovRadiansY: camera.fovRadiansY,
          aspectRatio: aspectRatio,
        );

        final nearBoardEdge = _ndc(
          viewProjection,
          vm.Vector3(0, 0, -boardHeight / 2),
        );

        expect(nearBoardEdge.y, closeTo(-1, 1e-4));
        expect(target, greaterThan(-boardHeight / 2));
      });
    });

    group('smoothing', () {
      const camera = BoardCamera();

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
