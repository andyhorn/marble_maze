import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_cubit.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';
import 'package:level_presentation/level_play/view/board_scene_view.dart';
import 'package:level_presentation/level_play/view/level_play_error_view.dart';
import 'package:level_presentation/level_play/view/level_play_hud.dart';
import 'package:level_presentation/level_play/view/level_play_loading_view.dart';
import 'package:level_presentation/level_play/view/level_play_ready_overlay.dart';
import 'package:level_presentation/level_play/view/level_play_view.dart';
import 'package:level_presentation/level_play/view/level_play_won_overlay.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';

/// Builds the widget that renders the board and marble, in place of
/// [BoardSceneView] for widget tests, since Flutter GPU does not render in
/// tests.
typedef BoardBuilder = Widget Function({
  required Level level,
  required IMarbleSimulation simulation,
  required bool isSimulationActive,
  required VoidCallback onMarbleFell,
  required VoidCallback onMarbleRespawned,
  required VoidCallback onReachedExit,
});

/// The level play screen's module: wires a level play cubit to the
/// [ILevelsRepository] from context, and shows loading, the board with its
/// state-specific overlay, or an error view for [levelId].
class LevelPlayModule extends StatelessWidget {
  /// Creates a level play module for [levelId].
  ///
  /// [simulationFactory] builds the [IMarbleSimulation] used once the level
  /// loads; [onExitToLevels] is called from the error and won views' back
  /// button. [boardBuilder] defaults to building a [BoardSceneView]; widget
  /// tests override it with a placeholder.
  const new({
    required this.levelId,
    required this.simulationFactory,
    required this.onExitToLevels,
    this.boardBuilder = BoardSceneView.new,
    super.key,
  });

  /// The id of the level to load and play.
  final String levelId;

  /// Builds the simulation the board steps each frame.
  final IMarbleSimulation Function() simulationFactory;

  /// Called when the player leaves an unrecoverable error state, or taps
  /// back to levels from the win overlay.
  final VoidCallback onExitToLevels;

  /// Builds the 3D board view. Defaults to [BoardSceneView.new].
  final BoardBuilder boardBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = LevelPlayCubit(
          repository: context.read<ILevelsRepository>(),
        );
        unawaited(cubit.load(levelId));
        return cubit;
      },
      child: _LevelPlayModuleBody(
        simulationFactory: simulationFactory,
        onExitToLevels: onExitToLevels,
        boardBuilder: boardBuilder,
      ),
    );
  }
}

class _LevelPlayModuleBody extends StatefulWidget {
  const new({
    required this.simulationFactory,
    required this.onExitToLevels,
    required this.boardBuilder,
  });

  final IMarbleSimulation Function() simulationFactory;
  final VoidCallback onExitToLevels;
  final BoardBuilder boardBuilder;

  @override
  State<_LevelPlayModuleBody> createState() => _LevelPlayModuleBodyState();
}

class _LevelPlayModuleBodyState extends State<_LevelPlayModuleBody> {
  IMarbleSimulation? _simulation;

  IMarbleSimulation get _simulationForPlay =>
      _simulation ??= widget.simulationFactory();

  @override
  void dispose() {
    _simulation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LevelPlayCubit>();
    return BlocBuilder<LevelPlayCubit, LevelPlayState>(
      builder: (context, state) => switch (state) {
        LevelPlayLoading() => const LevelPlayLoadingView(),
        LevelPlayReady(:final level) => LevelPlayView(
          boardView: widget.boardBuilder(
            level: level,
            simulation: _simulationForPlay,
            isSimulationActive: false,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
          ),
          overlay: LevelPlayReadyOverlay(onStart: cubit.start),
        ),
        // Falling renders the same subtree as Playing (the board stays up
        // while the marble sinks), so both branches build a BoardSceneView
        // rather than swapping widget types, which would recreate its
        // state mid-fall.
        LevelPlayPlaying(:final level) ||
        LevelPlayFalling(:final level) => LevelPlayView(
          boardView: widget.boardBuilder(
            level: level,
            simulation: _simulationForPlay,
            isSimulationActive: true,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
          ),
          overlay: LevelPlayHud(cubit: cubit, title: level.title),
        ),
        LevelPlayWon(:final level, :final time, :final par) => LevelPlayView(
          boardView: widget.boardBuilder(
            level: level,
            simulation: _simulationForPlay,
            isSimulationActive: false,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
          ),
          overlay: LevelPlayWonOverlay(
            time: time,
            par: par,
            onBackToLevels: widget.onExitToLevels,
          ),
        ),
        LevelPlayError() => LevelPlayErrorView(
          onBackToLevels: widget.onExitToLevels,
        ),
      },
    );
  }
}
