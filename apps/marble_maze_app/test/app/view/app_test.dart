import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/app.dart';

void main() {
  group('App', () {
    testWidgets('renders LevelPlayView with the injected board view', (
      tester,
    ) async {
      await tester.pumpWidget(const App(boardView: Placeholder()));

      expect(find.byType(LevelPlayView), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
