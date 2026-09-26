import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayWonOverlay', () {
    testWidgets('shows the finishing time and par when the level has one', (
      tester,
    ) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: const Duration(seconds: 30),
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: () {},
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('Time: 0:42.00'), findsOneWidget);
      expect(find.text('Par: 0:30.00'), findsOneWidget);
    });

    testWidgets('hides the par when the level has none', (tester) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: () {},
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('Time: 0:42.00'), findsOneWidget);
      expect(find.textContaining('Par:'), findsNothing);
    });

    testWidgets('shows the best time', (tester) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 30),
          isNewBest: false,
          onNext: () {},
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('Best: 0:30.00'), findsOneWidget);
    });

    testWidgets('shows a new best badge when isNewBest', (tester) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: true,
          onNext: () {},
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('New best!'), findsOneWidget);
    });

    testWidgets('hides the new best badge when it is not a new best', (
      tester,
    ) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 30),
          isNewBest: false,
          onNext: () {},
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('New best!'), findsNothing);
    });

    testWidgets('hides Next when onNext is null', (tester) async {
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: null,
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      expect(find.text('Next'), findsNothing);
    });

    testWidgets('calls onNext when Next is tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: () => tapped = true,
          onRetry: () {},
          onBackToLevels: () {},
        ),
      );

      await tester.tap(find.text('Next'));

      expect(tapped, isTrue);
    });

    testWidgets('calls onRetry when Retry is tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: null,
          onRetry: () => tapped = true,
          onBackToLevels: () {},
        ),
      );

      await tester.tap(find.text('Retry'));

      expect(tapped, isTrue);
    });

    testWidgets('calls onBackToLevels when Levels is tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          bestTime: const Duration(seconds: 42),
          isNewBest: false,
          onNext: null,
          onRetry: () {},
          onBackToLevels: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Back to levels'));

      expect(tapped, isTrue);
    });
  });
}
