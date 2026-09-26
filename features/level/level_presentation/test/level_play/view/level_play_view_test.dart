import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('LevelPlayView', () {
    testWidgets('renders the injected board view', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LevelPlayView(boardView: Placeholder())),
      );

      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
