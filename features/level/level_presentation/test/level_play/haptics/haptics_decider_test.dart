import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/haptics/haptics_decider.dart';
import 'package:simulation_domain/simulation_domain.dart';

void main() {
  group('HapticsDecider', () {
    const decider = HapticsDecider();

    test('a fast HitWall gets a light impact', () {
      final impact = decider.decide(const HitWall(5), Duration.zero);

      expect(impact, HapticImpact.light);
    });

    test('a HitWall below the speed threshold gets no impact', () {
      final impact = decider.decide(const HitWall(1), Duration.zero);

      expect(impact, HapticImpact.none);
    });

    test(
      'a HitWall within the debounce window of the last impact is muted',
      () {
        final impact = decider.decide(
          const HitWall(5),
          const Duration(milliseconds: 100),
          lastWallHitImpactElapsed: const Duration(milliseconds: 20),
        );

        expect(impact, HapticImpact.none);
      },
    );

    test('a HitWall after the debounce window fires again', () {
      final impact = decider.decide(
        const HitWall(5),
        const Duration(milliseconds: 300),
        lastWallHitImpactElapsed: const Duration(milliseconds: 20),
      );

      expect(impact, HapticImpact.light);
    });

    test('FellInHole gets a medium impact', () {
      final impact = decider.decide(
        const FellInHole(GridPoint(column: 0, row: 0)),
        Duration.zero,
      );

      expect(impact, HapticImpact.medium);
    });

    test('LeftBoard gets a medium impact', () {
      final impact = decider.decide(const LeftBoard(), Duration.zero);

      expect(impact, HapticImpact.medium);
    });

    test('ReachedExit gets no impact', () {
      final impact = decider.decide(const ReachedExit(), Duration.zero);

      expect(impact, HapticImpact.none);
    });
  });
}
