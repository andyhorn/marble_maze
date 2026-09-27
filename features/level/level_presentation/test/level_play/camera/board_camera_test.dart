import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

void main() {
  group('BoardCamera', () {
    const camera = BoardCamera();
    const aspectRatio = 9 / 16;

    test('a small level fits on screen and stays centered', () {
      expect(
        camera.fitsOnScreen(
          boardWidth: 9,
          boardHeight: 9,
          viewportAspectRatio: aspectRatio,
        ),
        isTrue,
      );

      final targetNearStart = camera.targetZFor(
        marbleZ: -3,
        boardWidth: 9,
        boardHeight: 9,
        viewportAspectRatio: aspectRatio,
      );
      final targetNearEnd = camera.targetZFor(
        marbleZ: 3,
        boardWidth: 9,
        boardHeight: 9,
        viewportAspectRatio: aspectRatio,
      );

      expect(targetNearStart, 0);
      expect(targetNearEnd, 0);
    });

    test('a tall level does not fit and the target follows the marble', () {
      const boardWidth = 9.0;
      const boardHeight = 40.0;

      expect(
        camera.fitsOnScreen(
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          viewportAspectRatio: aspectRatio,
        ),
        isFalse,
      );

      final target = camera.targetZFor(
        marbleZ: 5,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
        viewportAspectRatio: aspectRatio,
      );

      expect(target, 5);
    });

    test('the follow target is clamped to the board edges', () {
      const boardWidth = 9.0;
      const boardHeight = 40.0;

      final target = camera.targetZFor(
        marbleZ: 100,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
        viewportAspectRatio: aspectRatio,
      );

      expect(target, lessThan(boardHeight / 2));
      expect(target, greaterThan(0));
    });

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
}
