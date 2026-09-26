import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_cubit.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';
import 'package:level_presentation/level_play/view/board_scene_view.dart';
import 'package:level_presentation/level_play/view/level_play_error_view.dart';
import 'package:level_presentation/level_play/view/level_play_loading_view.dart';
import 'package:level_presentation/level_play/view/level_play_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';

/// The level play screen's module: wires a level play cubit to the
/// [ILevelsRepository] from context, and shows loading, the board, or an
/// error view for [levelId].
class LevelPlayModule extends StatelessWidget {
  /// Creates a level play module for [levelId].
  ///
  /// [simulationFactory] builds the [IMarbleSimulation] used once the level
  /// loads; [onExitToLevels] is called from the error view's back button.
  const new({
    required this.levelId,
    required this.simulationFactory,
    required this.onExitToLevels,
    super.key,
  });

  /// The id of the level to load and play.
  final String levelId;

  /// Builds the simulation the board steps each frame.
  final IMarbleSimulation Function() simulationFactory;

  /// Called when the player leaves an unrecoverable error state.
  final VoidCallback onExitToLevels;

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
      ),
    );
  }
}

class _LevelPlayModuleBody extends StatefulWidget {
  const new({required this.simulationFactory, required this.onExitToLevels});

  final IMarbleSimulation Function() simulationFactory;
  final VoidCallback onExitToLevels;

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
    return BlocBuilder<LevelPlayCubit, LevelPlayState>(
      builder: (context, state) => switch (state) {
        LevelPlayLoading() => const LevelPlayLoadingView(),
        // Falling renders the same subtree as Playing (the board stays up
        // while the marble sinks), so both branches build a BoardSceneView
        // rather than swapping widget types, which would recreate its
        // state mid-fall.
        LevelPlayPlaying(:final level) ||
        LevelPlayFalling(:final level) => LevelPlayView(
          boardView: BoardSceneView(
            level: level,
            simulation: _simulationForPlay,
            onMarbleFell: () => context.read<LevelPlayCubit>().marbleFell(),
            onMarbleRespawned: () =>
                context.read<LevelPlayCubit>().marbleRespawned(),
          ),
        ),
        LevelPlayError() => LevelPlayErrorView(
          onBackToLevels: widget.onExitToLevels,
        ),
      },
    );
  }
}
