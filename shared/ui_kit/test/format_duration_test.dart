import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('formatDuration', () {
    test('formats zero as minutes:seconds.centiseconds', () {
      expect(formatDuration(Duration.zero), '0:00.00');
    });

    test('formats a time under a minute', () {
      expect(
        formatDuration(const Duration(seconds: 5, milliseconds: 320)),
        '0:05.32',
      );
    });

    test('formats a time over a minute without hours', () {
      expect(
        formatDuration(
          const Duration(minutes: 1, seconds: 5, milliseconds: 320),
        ),
        '1:05.32',
      );
    });

    test('formats a time over an hour with an hours component', () {
      expect(
        formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 400),
        ),
        '1:02:03.40',
      );
    });

    test('truncates milliseconds to centiseconds', () {
      expect(
        formatDuration(const Duration(seconds: 1, milliseconds: 999)),
        '0:01.99',
      );
    });
  });
}
