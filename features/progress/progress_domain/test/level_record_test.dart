import 'package:progress_domain/progress_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LevelRecord', () {
    test('equal records with the same levelId and bestTime are ==', () {
      const a = LevelRecord(
        levelId: 'first_roll',
        bestTime: Duration(seconds: 10),
      );
      const b = LevelRecord(
        levelId: 'first_roll',
        bestTime: Duration(seconds: 10),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('records with a different bestTime are not ==', () {
      const a = LevelRecord(
        levelId: 'first_roll',
        bestTime: Duration(seconds: 10),
      );
      const b = LevelRecord(
        levelId: 'first_roll',
        bestTime: Duration(seconds: 11),
      );

      expect(a, isNot(b));
    });
  });
}
