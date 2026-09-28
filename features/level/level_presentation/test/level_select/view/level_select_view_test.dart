import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

void main() {
  group('LevelSelectView', () {
    late _MockLevelsRepository levelsRepository;
    late _MockProgressRepository progressRepository;

    setUp(() {
      levelsRepository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
      when(() => levelsRepository.getManifest()).thenAnswer(
        (_) async => const [
          LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
        ],
      );
    });

    testWidgets(
      'reloads and shows a newly saved best time after the player returns '
      'from another route',
      (tester) async {
        when(() => progressRepository.getRecords()).thenAnswer((_) async => {});

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [levelSelectRouteObserver],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepositoryProvider<ILevelsRepository>.value(
              value: levelsRepository,
              child: RepositoryProvider<IProgressRepository>.value(
                value: progressRepository,
                child: LevelSelectModule(
                  onLevelSelected: (id) {},
                  onOpenBubbleLevel: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('No best time yet'), findsOneWidget);

        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              MaterialPageRoute<void>(
                builder: (context) => const Scaffold(body: Text('other route')),
              ),
            );
        await tester.pumpAndSettle();

        when(() => progressRepository.getRecords()).thenAnswer(
          (_) async => {
            'first_roll': const LevelRecord(
              levelId: 'first_roll',
              bestTime: Duration(seconds: 18),
            ),
          },
        );

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();

        expect(find.textContaining('Best: 0:18.00'), findsOneWidget);
      },
    );
  });
}
