import 'package:flutter_test/flutter_test.dart';
import 'package:marble_maze_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('buildApp', () {
    testWidgets(
      "shows the unsupported-device screen when Flutter GPU isn't available",
      (tester) async {
        final widget = await buildApp(isFlutterGpuAvailable: () async => false);

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(UnsupportedDeviceApp), findsOneWidget);
        expect(find.byType(App), findsNothing);
      },
    );

    testWidgets('shows the level list when Flutter GPU is available', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final widget = await buildApp(isFlutterGpuAvailable: () async => true);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byType(App), findsOneWidget);
      expect(find.byType(UnsupportedDeviceApp), findsNothing);
      expect(find.text('First Roll'), findsOneWidget);
    });
  });
}
