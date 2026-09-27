import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayPausedOverlay', () {
    testWidgets('shows the paused title', (tester) async {
      await tester.pumpApp(
        LevelPlayPausedOverlay(onResume: () {}, onBackToLevels: () {}),
      );

      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('calls onResume when Resume is tapped', (tester) async {
      var resumed = false;
      await tester.pumpApp(
        LevelPlayPausedOverlay(
          onResume: () => resumed = true,
          onBackToLevels: () {},
        ),
      );

      await tester.tap(find.text('Resume'));

      expect(resumed, isTrue);
    });

    testWidgets('calls onBackToLevels when Back to levels is tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayPausedOverlay(
          onResume: () {},
          onBackToLevels: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Back to levels'));

      expect(tapped, isTrue);
    });

    testWidgets(
      'absorbs taps outside the panel rather than passing them through',
      (tester) async {
        var boardTapped = false;
        await tester.pumpApp(
          Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => boardTapped = true,
                child: const SizedBox.expand(),
              ),
              LevelPlayPausedOverlay(onResume: () {}, onBackToLevels: () {}),
            ],
          ),
        );

        await tester.tapAt(const Offset(5, 5));

        expect(boardTapped, isFalse);
      },
    );
  });
}
