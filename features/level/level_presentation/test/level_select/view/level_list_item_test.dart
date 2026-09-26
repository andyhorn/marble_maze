import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

// ListTile requires a Material ancestor.
Widget _wrap(Widget child) => Material(child: child);

void main() {
  group('LevelListItem', () {
    testWidgets('shows the title and best time', (tester) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: Duration(seconds: 18),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('First Roll'), findsOneWidget);
      expect(find.textContaining('Best: 0:18.00'), findsOneWidget);
    });

    testWidgets('shows no best time message when there is none', (
      tester,
    ) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: null,
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('No best time yet'), findsOneWidget);
    });

    testWidgets('shows par beaten when the best time beats par', (
      tester,
    ) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: Duration(seconds: 18),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Par beaten'), findsOneWidget);
    });

    testWidgets('shows par not beaten when the best time does not beat par', (
      tester,
    ) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: Duration(seconds: 25),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Par not beaten'), findsOneWidget);
    });

    testWidgets('shows par not beaten when there is no best time', (
      tester,
    ) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: null,
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Par not beaten'), findsOneWidget);
    });

    testWidgets('shows no par when the level has none', (tester) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: null,
              bestTime: null,
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('No par time'), findsOneWidget);
    });

    testWidgets('an equal best time and par counts as beaten', (tester) async {
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: Duration(seconds: 20),
              bestTime: Duration(seconds: 20),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Par beaten'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        _wrap(
          LevelListItem(
            entry: const LevelListEntry(
              id: 'first_roll',
              title: 'First Roll',
              par: null,
              bestTime: null,
            ),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('First Roll'));

      expect(tapped, isTrue);
    });
  });
}
