import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilt_domain/tilt_domain.dart';

import '../../helpers/pump_app.dart';

class _MockTiltRepository extends Mock implements ITiltRepository;

void main() {
  group('BubbleLevelModule', () {
    late _MockTiltRepository tiltRepository;
    late StreamController<RawGravity> gravity;

    setUp(() {
      tiltRepository = _MockTiltRepository();
      gravity = StreamController<RawGravity>();
      when(() => tiltRepository.watchGravity())
          .thenAnswer((_) => gravity.stream);
    });

    tearDown(() => gravity.close());

    Widget buildSubject() => RepositoryProvider<ITiltRepository>.value(
      value: tiltRepository,
      child: const BubbleLevelModule(),
    );

    testWidgets('waits for the accelerometer before the first reading', (
      tester,
    ) async {
      await tester.pumpApp(buildSubject());

      expect(find.text('Waiting for the accelerometer…'), findsOneWidget);
      expect(find.byType(BubbleLevelGauge), findsNothing);
    });

    testWidgets('shows the tilt in degrees once a reading arrives', (
      tester,
    ) async {
      const angle = 5 * math.pi / 180;
      await tester.pumpApp(buildSubject());

      gravity.add(
        RawGravity(x: 9.81 * math.sin(angle), y: 0, z: 9.81 * math.cos(angle)),
      );
      await tester.pump();

      expect(find.byType(BubbleLevelGauge), findsOneWidget);
      expect(find.text('X 5.0°   Y 0.0°'), findsOneWidget);
    });
  });
}
