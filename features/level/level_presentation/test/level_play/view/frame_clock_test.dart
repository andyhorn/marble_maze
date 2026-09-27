import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

void main() {
  group('FrameClock', () {
    test('a normal delta passes through unchanged', () {
      final clock = FrameClock();

      final first = clock.tick(
        const Duration(milliseconds: 16),
        isActive: true,
      );
      final second = clock.tick(
        const Duration(milliseconds: 32),
        isActive: true,
      );

      expect(first, const Duration(milliseconds: 16));
      expect(second, const Duration(milliseconds: 16));
    });

    test('a large gap is clamped to the default maxDelta', () {
      final clock = FrameClock();

      final delta = clock.tick(const Duration(seconds: 30), isActive: true);

      expect(delta, const Duration(milliseconds: 33));
    });

    test('inactive ticks do not advance activeElapsed', () {
      final clock = FrameClock();

      final firstDelta = clock.tick(
        const Duration(milliseconds: 16),
        isActive: false,
      );
      final secondDelta = clock.tick(
        const Duration(milliseconds: 32),
        isActive: false,
      );

      expect(firstDelta, const Duration(milliseconds: 16));
      expect(secondDelta, const Duration(milliseconds: 16));
      expect(clock.activeElapsed, Duration.zero);
    });

    test('active ticks accumulate into activeElapsed', () {
      final clock = FrameClock();

      final firstDelta = clock.tick(
        const Duration(milliseconds: 16),
        isActive: true,
      );
      final secondDelta = clock.tick(
        const Duration(milliseconds: 32),
        isActive: true,
      );

      expect(firstDelta, const Duration(milliseconds: 16));
      expect(secondDelta, const Duration(milliseconds: 16));
      expect(clock.activeElapsed, const Duration(milliseconds: 32));
    });

    test('the first active tick after a long inactive stretch advances by at '
        'most maxDelta', () {
      final clock = FrameClock();
      final beforeStall = clock.tick(
        const Duration(milliseconds: 16),
        isActive: true,
      );
      // The app was backgrounded for 30 s: no frames were scheduled, so no
      // ticks occurred, and the next tick's timestamp jumps by the whole
      // gap.
      final delta = clock.tick(
        const Duration(seconds: 30, milliseconds: 16),
        isActive: true,
      );

      expect(beforeStall, const Duration(milliseconds: 16));
      expect(delta, const Duration(milliseconds: 33));
      expect(clock.activeElapsed, const Duration(milliseconds: 49));
    });
  });
}
