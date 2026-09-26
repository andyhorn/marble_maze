import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayTiltHint', () {
    testWidgets('shows the drag to tilt hint', (tester) async {
      await tester.pumpApp(const LevelPlayTiltHint());

      expect(find.text('Drag to tilt'), findsOneWidget);
    });

    testWidgets('ignores pointer events so it never blocks a drag', (
      tester,
    ) async {
      await tester.pumpApp(const LevelPlayTiltHint());

      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(LevelPlayTiltHint),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });
  });
}
