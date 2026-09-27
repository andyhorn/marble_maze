import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

void main() {
  group('MarbleExitAnimation', () {
    const animation = MarbleExitAnimation();

    test('has not completed before its duration', () {
      expect(
        animation.isCompleteAt(const Duration(milliseconds: 599)),
        isFalse,
      );
    });

    test('has completed at its duration', () {
      expect(animation.isCompleteAt(const Duration(milliseconds: 600)), isTrue);
    });

    test('progress is 0 at the start', () {
      expect(animation.progressAt(Duration.zero), 0);
    });

    test('progress is 1 once complete', () {
      expect(animation.progressAt(const Duration(milliseconds: 600)), 1);
    });

    test('progress does not exceed 1 past the duration', () {
      expect(animation.progressAt(const Duration(seconds: 2)), 1);
    });

    test('progress increases monotonically over the duration', () {
      final early = animation.progressAt(const Duration(milliseconds: 100));
      final late = animation.progressAt(const Duration(milliseconds: 500));

      expect(late, greaterThan(early));
    });

    test(
      'sink offset starts at 0 and reaches the full depth once complete',
      () {
        expect(animation.sinkOffsetAt(Duration.zero), 0);
        expect(animation.sinkOffsetAt(const Duration(milliseconds: 600)), 0.5);
      },
    );

    test('a zero duration completes immediately', () {
      const instant = MarbleExitAnimation(duration: Duration.zero);

      expect(instant.isCompleteAt(Duration.zero), isTrue);
      expect(instant.progressAt(Duration.zero), 1);
    });
  });
}
