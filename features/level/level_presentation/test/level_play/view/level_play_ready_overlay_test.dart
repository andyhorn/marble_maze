import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayReadyOverlay', () {
    testWidgets('shows the tap to start prompt', (tester) async {
      await tester.pumpApp(LevelPlayReadyOverlay(onStart: () {}));

      expect(find.text('Tap to start'), findsOneWidget);
    });

    testWidgets('calls onStart when tapped', (tester) async {
      var started = false;
      await tester.pumpApp(
        LevelPlayReadyOverlay(onStart: () => started = true),
      );

      await tester.tap(find.byType(LevelPlayReadyOverlay));

      expect(started, isTrue);
    });
  });
}
