import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LevelPlayView', () {
    testWidgets('renders the injected board view', (tester) async {
      await tester.pumpApp(const LevelPlayView(boardView: Placeholder()));

      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('renders the overlay over the board view', (tester) async {
      await tester.pumpApp(
        const LevelPlayView(boardView: Placeholder(), overlay: Text('overlay')),
      );

      expect(find.text('overlay'), findsOneWidget);
    });
  });
}
