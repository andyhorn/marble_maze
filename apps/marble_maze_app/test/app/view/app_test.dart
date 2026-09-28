import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/app.dart';
import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:settings_domain/settings_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

/// Reports no accelerometer, so these tests exercise the touch-only
/// fallback without waiting on the real 500 ms probe window.
class _FakeTiltRepository implements ITiltRepository {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<RawGravity> watchGravity() => const Stream.empty();
}

class _FakeSettingsRepository implements ISettingsRepository {
  @override
  Future<bool> getCalibrateTilt() async => true;

  @override
  Future<void> setCalibrateTilt({required bool value}) async {}
}

void main() {
  group('App', () {
    late _MockLevelsRepository repository;
    late _MockProgressRepository progressRepository;

    setUp(() {
      repository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
      when(() => repository.getManifest()).thenAnswer(
        (_) async => const [
          LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
        ],
      );
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});
    });

    Widget buildSubject({GoRouter? router}) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ILevelsRepository>.value(value: repository),
          RepositoryProvider<IProgressRepository>.value(
            value: progressRepository,
          ),
          RepositoryProvider<ITiltRepository>.value(
            value: _FakeTiltRepository(),
          ),
          RepositoryProvider<ISettingsRepository>.value(
            value: _FakeSettingsRepository(),
          ),
        ],
        child: App(router: router ?? GoRouter(routes: $appRoutes)),
      );
    }

    testWidgets('renders the level select screen at the initial route', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('First Roll'), findsOneWidget);
    });

    testWidgets('opens settings, then the bubble level, from level select', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsView), findsOneWidget);

      await tester.tap(find.text('Bubble level'));
      await tester.pumpAndSettle();

      expect(find.byType(BubbleLevelView), findsOneWidget);
    });

    testWidgets('opens the level play route from level select', (tester) async {
      // A never-completing future, rather than Future.delayed, so no timer
      // is left pending when the test tears down.
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) => Completer<Level>().future);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await tester.tap(find.text('First Roll'));
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('First Roll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to levels'));
      await tester.pumpAndSettle();

      expect(find.text('First Roll'), findsOneWidget);
    });

    testWidgets(
      'replacing the level play route with a different id reloads the '
      "level, matching what the win overlay's Next button does",
      (tester) async {
        when(() => repository.getLevel('first_roll'))
            .thenAnswer((_) => Completer<Level>().future);
        when(() => repository.getLevel('second_roll'))
            .thenAnswer((_) => Completer<Level>().future);
        final router = GoRouter(
          routes: $appRoutes,
          initialLocation: '/level/first_roll',
        );

        await tester.pumpWidget(buildSubject(router: router));
        await tester.pump();
        await tester.pump();
        verify(() => repository.getLevel('first_roll')).called(1);

        const LevelPlayRoute(id: 'second_roll')
            .replace(tester.element(find.byType(LevelPlayLoadingView)));
        await tester.pump();
        await tester.pump();

        verify(() => repository.getLevel('second_roll')).called(1);
      },
    );
  });
}
