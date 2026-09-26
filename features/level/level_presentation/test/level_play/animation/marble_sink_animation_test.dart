import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

void main() {
  group('MarbleSinkAnimation', () {
    const animation = MarbleSinkAnimation();

    test('has not completed before its duration', () {
      expect(
        animation.isCompleteAt(const Duration(milliseconds: 499)),
        isFalse,
      );
    });

    test('has completed at its duration', () {
      expect(animation.isCompleteAt(const Duration(milliseconds: 500)), isTrue);
    });

    test('has completed past its duration', () {
      expect(animation.isCompleteAt(const Duration(seconds: 1)), isTrue);
    });

    test('progress is 0 at the start', () {
      expect(animation.progressAt(Duration.zero), 0);
    });

    test('progress is 1 once complete', () {
      expect(animation.progressAt(const Duration(milliseconds: 500)), 1);
    });

    test('progress does not exceed 1 past the duration', () {
      expect(animation.progressAt(const Duration(seconds: 1)), 1);
    });

    test('progress increases monotonically over the duration', () {
      final early = animation.progressAt(const Duration(milliseconds: 100));
      final late = animation.progressAt(const Duration(milliseconds: 400));

      expect(late, greaterThan(early));
    });

    test('scale starts at 1 and reaches 0 once complete', () {
      expect(animation.scaleAt(Duration.zero), 1);
      expect(animation.scaleAt(const Duration(milliseconds: 500)), 0);
    });

    test(
      'sink offset starts at 0 and reaches the full depth once complete',
      () {
        const withDepth = MarbleSinkAnimation();

        expect(withDepth.sinkOffsetAt(Duration.zero), 0);
        expect(withDepth.sinkOffsetAt(const Duration(milliseconds: 500)), 0.5);
      },
    );

    test('a zero duration completes and scales to 0 immediately', () {
      const instant = MarbleSinkAnimation(duration: Duration.zero);

      expect(instant.isCompleteAt(Duration.zero), isTrue);
      expect(instant.scaleAt(Duration.zero), 0);
    });
  });
}
