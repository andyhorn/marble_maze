import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/app.dart';
import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:marble_maze_app/app/view/home_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilt_domain/tilt_domain.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

/// Reports no accelerometer, so these tests exercise the touch-only
/// fallback without waiting on the real 500 ms probe window.
class _FakeTiltRepository implements ITiltRepository {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<RawGravity> watchGravity() => const Stream.empty();
}

void main() {
  group('App', () {
    late _MockLevelsRepository repository;

    setUp(() {
      repository = _MockLevelsRepository();
    });

    Widget buildSubject() {
      return RepositoryProvider<ILevelsRepository>.value(
        value: repository,
        child: RepositoryProvider<ITiltRepository>.value(
          value: _FakeTiltRepository(),
          child: App(router: GoRouter(routes: $appRoutes)),
        ),
      );
    }

    testWidgets('renders the home page at the initial route', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('opens the level play route from the home page', (
      tester,
    ) async {
      // A never-completing future, rather than Future.delayed, so no timer
      // is left pending when the test tears down.
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) => Completer<Level>().future);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Play First Roll'));
      // Not pumpAndSettle: the loading view's CircularProgressIndicator
      // animates indefinitely, so it never settles.
      await tester.pump();
      await tester.pump();

      expect(find.byType(LevelPlayLoadingView), findsOneWidget);
    });

    testWidgets('shows a way back from an unknown level id', (tester) async {
      when(() => repository.getLevel('first_roll'))
          .thenThrow(const LevelNotFoundException('first_roll'));

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Play First Roll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to levels'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
