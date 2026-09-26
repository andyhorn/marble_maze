import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayErrorView', () {
    testWidgets('calls onBackToLevels when the button is tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        LevelPlayErrorView(onBackToLevels: () => tapped = true),
      );

      await tester.tap(find.text('Back to levels'));

      expect(tapped, isTrue);
    });
  });
}
