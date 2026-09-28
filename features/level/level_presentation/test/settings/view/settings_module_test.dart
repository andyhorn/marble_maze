import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings_domain/settings_domain.dart';

import '../../helpers/pump_app.dart';

class _MockSettingsRepository extends Mock implements ISettingsRepository;

void main() {
  group('SettingsModule', () {
    late _MockSettingsRepository settingsRepository;

    setUp(() {
      settingsRepository = _MockSettingsRepository();
      when(
        () => settingsRepository.setCalibrateTilt(value: any(named: 'value')),
      ).thenAnswer((_) async {});
    });

    Widget buildSubject({VoidCallback? onOpenBubbleLevel}) =>
        RepositoryProvider<ISettingsRepository>.value(
          value: settingsRepository,
          child: SettingsModule(onOpenBubbleLevel: onOpenBubbleLevel ?? () {}),
        );

    testWidgets('shows the saved calibrate tilt setting', (tester) async {
      when(() => settingsRepository.getCalibrateTilt())
          .thenAnswer((_) async => false);

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets('saves the setting when the switch is toggled', (tester) async {
      when(() => settingsRepository.getCalibrateTilt())
          .thenAnswer((_) async => true);

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      verify(() => settingsRepository.setCalibrateTilt(value: false)).called(1);
    });

    testWidgets('calls onOpenBubbleLevel when the bubble level row is tapped', (
      tester,
    ) async {
      var opened = false;
      when(() => settingsRepository.getCalibrateTilt())
          .thenAnswer((_) async => true);

      await tester.pumpApp(
        buildSubject(onOpenBubbleLevel: () => opened = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bubble level'));

      expect(opened, isTrue);
    });
  });
}
