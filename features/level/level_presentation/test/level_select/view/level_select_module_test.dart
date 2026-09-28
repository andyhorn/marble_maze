import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_domain/progress_domain.dart';

import '../../helpers/pump_app.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _MockProgressRepository extends Mock implements IProgressRepository;

void main() {
  group('LevelSelectModule', () {
    late _MockLevelsRepository levelsRepository;
    late _MockProgressRepository progressRepository;

    setUp(() {
      levelsRepository = _MockLevelsRepository();
      progressRepository = _MockProgressRepository();
    });

    Widget buildSubject({
      ValueChanged<String>? onLevelSelected,
      VoidCallback? onOpenBubbleLevel,
    }) {
      return RepositoryProvider<ILevelsRepository>.value(
        value: levelsRepository,
        child: RepositoryProvider<IProgressRepository>.value(
          value: progressRepository,
          child: LevelSelectModule(
            onLevelSelected: onLevelSelected ?? (_) {},
            onOpenBubbleLevel: onOpenBubbleLevel ?? () {},
          ),
        ),
      );
    }

    testWidgets('shows a loading view while the manifest loads', (
      tester,
    ) async {
      when(() => levelsRepository.getManifest())
          .thenAnswer((_) => Completer<List<LevelManifestEntry>>().future);
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});

      await tester.pumpApp(buildSubject());

      expect(find.byType(LevelSelectLoadingView), findsOneWidget);
    });

    testWidgets('shows every level once the manifest loads', (tester) async {
      when(() => levelsRepository.getManifest()).thenAnswer(
        (_) async => const [
          LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
          LevelManifestEntry(id: 'second_roll', title: 'Second Roll'),
        ],
      );
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('First Roll'), findsOneWidget);
      expect(find.text('Second Roll'), findsOneWidget);
    });

    testWidgets('calls onLevelSelected when a row is tapped', (tester) async {
      String? selected;
      when(() => levelsRepository.getManifest()).thenAnswer(
        (_) async => const [
          LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
        ],
      );
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});

      await tester.pumpApp(
        buildSubject(onLevelSelected: (id) => selected = id),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('First Roll'));

      expect(selected, 'first_roll');
    });

    testWidgets('calls onOpenBubbleLevel when the bubble level button is '
        'tapped', (tester) async {
      var opened = false;
      when(() => levelsRepository.getManifest()).thenAnswer(
        (_) async => const [
          LevelManifestEntry(id: 'first_roll', title: 'First Roll'),
        ],
      );
      when(() => progressRepository.getRecords()).thenAnswer((_) async => {});

      await tester.pumpApp(
        buildSubject(onOpenBubbleLevel: () => opened = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bubble level'));

      expect(opened, isTrue);
    });
  });
}
