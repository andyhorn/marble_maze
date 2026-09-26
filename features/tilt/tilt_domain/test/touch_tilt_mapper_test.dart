import 'package:test/test.dart';
import 'package:tilt_domain/tilt_domain.dart';

void main() {
  group('TouchTiltMapper', () {
    late TouchTiltMapper mapper;

    setUp(() {
      mapper = TouchTiltMapper();
    });

    test('starts flat', () {
      expect(mapper.tilt, Tilt.flat);
    });

    test('dragging right gives positive x', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(60, 0);

      expect(mapper.tilt.x, greaterThan(0));
      expect(mapper.tilt.y, 0);
    });

    test('dragging up gives positive y', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(0, -60);

      expect(mapper.tilt.y, greaterThan(0));
      expect(mapper.tilt.x, 0);
    });

    test('reaches full tilt at 120 logical px', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(120, 0);

      expect(mapper.tilt.x, closeTo(Tilt.maxTilt, 1e-9));
    });

    test('clamps beyond the full-tilt distance', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(500, 500);

      expect(mapper.tilt.x, Tilt.maxTilt);
      expect(mapper.tilt.y, -Tilt.maxTilt);
    });

    test('ignores updates before a drag starts', () {
      mapper.dragUpdate(100, 100);

      expect(mapper.tilt, Tilt.flat);
    });

    test('eases back to flat after release', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(120, 0)
        ..dragEnd()
        ..update(const Duration(milliseconds: 125));
      final halfway = mapper.tilt.x;
      expect(halfway, greaterThan(0));
      expect(halfway, lessThan(Tilt.maxTilt));

      mapper.update(const Duration(milliseconds: 125));
      expect(mapper.tilt, Tilt.flat);
    });

    test('a new drag overrides an in-progress release ease', () {
      mapper
        ..dragStart(0, 0)
        ..dragUpdate(120, 0)
        ..dragEnd()
        ..update(const Duration(milliseconds: 50))
        ..dragStart(0, 0)
        ..dragUpdate(0, 0);

      expect(mapper.tilt, Tilt.flat);
    });
  });
}
