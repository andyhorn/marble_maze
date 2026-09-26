import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marble_maze_app/app/app.dart';
import 'package:marble_maze_app/scene_preview/scene_preview.dart';

void main() {
  group('App', () {
    testWidgets('renders ScenePreviewPage with the injected scene view', (
      tester,
    ) async {
      await tester.pumpWidget(const App(sceneView: Placeholder()));

      expect(find.byType(ScenePreviewPage), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
