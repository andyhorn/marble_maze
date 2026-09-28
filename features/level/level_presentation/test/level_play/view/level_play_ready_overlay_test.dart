import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayReadyOverlay', () {
    testWidgets('shows the tap to start prompt', (tester) async {
      await tester.pumpApp(
        LevelPlayReadyOverlay(onStart: () {}, onBackToLevels: () {}),
      );

      expect(find.text('Tap to start'), findsOneWidget);
    });

    testWidgets('calls onStart when tapped', (tester) async {
      var started = false;
      await tester.pumpApp(
        LevelPlayReadyOverlay(
          onStart: () => started = true,
          onBackToLevels: () {},
        ),
      );

      await tester.tap(find.text('Tap to start'));

      expect(started, isTrue);
    });

    testWidgets('calls onBackToLevels without starting when back is tapped', (
      tester,
    ) async {
      var started = false;
      var wentBack = false;
      await tester.pumpApp(
        LevelPlayReadyOverlay(
          onStart: () => started = true,
          onBackToLevels: () => wentBack = true,
        ),
      );

      await tester.tap(find.text('Back to levels'));

      expect(wentBack, isTrue);
      expect(started, isFalse);
    });
  });
}
