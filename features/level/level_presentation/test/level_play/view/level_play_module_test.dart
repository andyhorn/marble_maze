import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

class _MockLevelsRepository extends Mock implements ILevelsRepository;

class _FakeMarbleSimulation implements IMarbleSimulation {
  @override
  void load(Level level) {}

  @override
  void step(Tilt tilt, Duration elapsed) {}

  @override
  void respawn() {}

  @override
  MarbleState get marble => MarbleState(
    position: Vector3.zero(),
    rotation: Quaternion.identity(),
    velocity: Vector3.zero(),
    isActive: true,
  );

  @override
  Stream<SimulationEvent> get events => const Stream.empty();

  @override
  void dispose() {}
}

void main() {
  group('LevelPlayModule', () {
    late _MockLevelsRepository repository;

    setUp(() {
      repository = _MockLevelsRepository();
    });

    Widget buildSubject() {
      return RepositoryProvider<ILevelsRepository>.value(
        value: repository,
        child: MaterialApp(
          home: LevelPlayModule(
            levelId: 'first_roll',
            simulationFactory: _FakeMarbleSimulation.new,
            onExitToLevels: () {},
          ),
        ),
      );
    }

    testWidgets('shows a loading view while the level loads', (tester) async {
      // A never-completing future, rather than Future.delayed, so no timer
      // is left pending when the test tears down.
      when(() => repository.getLevel('first_roll'))
          .thenAnswer((_) => Completer<Level>().future);

      await tester.pumpWidget(buildSubject());

      expect(find.byType(LevelPlayLoadingView), findsOneWidget);
    });

    testWidgets('shows an error view for an unknown level', (tester) async {
      when(() => repository.getLevel('first_roll'))
          .thenThrow(const LevelNotFoundException('first_roll'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LevelPlayErrorView), findsOneWidget);
    });
  });
}
