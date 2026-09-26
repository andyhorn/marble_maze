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
          onBackToLevels: () {},
        ),
      );

      expect(find.text('Time: 0:42.00'), findsOneWidget);
      expect(find.textContaining('Par:'), findsNothing);
    });

    testWidgets('calls onBackToLevels when the button is tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayWonOverlay(
          time: const Duration(seconds: 42),
          par: null,
          onBackToLevels: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Back to levels'));

      expect(tapped, isTrue);
    });
  });
}
