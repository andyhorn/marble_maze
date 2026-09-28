import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_cubit.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';
import 'package:level_presentation/level_play/input/level_play_input_controller.dart';
import 'package:level_presentation/level_play/view/board_scene_view.dart';
import 'package:level_presentation/level_play/view/level_play_error_view.dart';
import 'package:level_presentation/level_play/view/level_play_loading_view.dart';
import 'package:level_presentation/level_play/view/level_play_paused_overlay.dart';
import 'package:level_presentation/level_play/view/level_play_playing_overlay.dart';
import 'package:level_presentation/level_play/view/level_play_ready_overlay.dart';
import 'package:level_presentation/level_play/view/level_play_view.dart';
import 'package:level_presentation/level_play/view/level_play_won_overlay.dart';
import 'package:material_ui/material_ui.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// Builds the widget that renders the board and marble, in place of
/// [BoardSceneView] for widget tests, since Flutter GPU does not render in
/// tests.
typedef BoardBuilder = Widget Function({
  required Level level,
  required IMarbleSimulation simulation,
  required bool isSimulationActive,
  required LevelPlayInputController controller,
  required VoidCallback onMarbleFell,
  required VoidCallback onMarbleRespawned,
  required VoidCallback onReachedExit,
  required VoidCallback onSceneReady,
});

/// The level play screen's module: wires a level play cubit to the
/// [ILevelsRepository] and [IProgressRepository] from context, and shows
/// loading, the board with its state-specific overlay, or an error view for
/// [levelId].
class LevelPlayModule extends StatelessWidget {
  /// Creates a level play module for [levelId].
  ///
  /// [simulationFactory] builds the [IMarbleSimulation] used once the level
  /// loads; [onExitToLevels] is called from the error and won views' back
  /// button, and [onNextLevel] from the won view's Next button.
  /// [boardBuilder] defaults to building a [BoardSceneView]; widget tests
  /// override it with a placeholder.
  const new({
    required this.levelId,
    required this.simulationFactory,
    required this.onExitToLevels,
    required this.onNextLevel,
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

  /// Called with the next level's id when the player taps Next on the win
  /// overlay.
  final ValueChanged<String> onNextLevel;

  /// Builds the 3D board view. Defaults to [BoardSceneView.new].
  final BoardBuilder boardBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = LevelPlayCubit(
          repository: context.read<ILevelsRepository>(),
          progressRepository: context.read<IProgressRepository>(),
        );
        unawaited(cubit.load(levelId));
        return cubit;
      },
      child: _LevelPlayModuleBody(
        simulationFactory: simulationFactory,
        onExitToLevels: onExitToLevels,
        onNextLevel: onNextLevel,
        boardBuilder: boardBuilder,
      ),
    );
  }
}

class _LevelPlayModuleBody extends StatefulWidget {
  const new({
    required this.simulationFactory,
    required this.onExitToLevels,
    required this.onNextLevel,
    required this.boardBuilder,
  });

  final IMarbleSimulation Function() simulationFactory;
  final VoidCallback onExitToLevels;
  final ValueChanged<String> onNextLevel;
  final BoardBuilder boardBuilder;

  @override
  State<_LevelPlayModuleBody> createState() => _LevelPlayModuleBodyState();
}

class _LevelPlayModuleBodyState extends State<_LevelPlayModuleBody> {
  IMarbleSimulation? _simulation;
  bool _isSceneReady = false;
  late final LevelPlayInputController _controller;
  late final AppLifecycleListener _lifecycleListener;

  IMarbleSimulation get _simulationForPlay =>
      _simulation ??= widget.simulationFactory();

  @override
  void initState() {
    super.initState();
    _controller = LevelPlayInputController(
      repository: context.read<ITiltRepository>(),
    );
    unawaited(_controller.initialize());
    // Only pauses: the player must tap Resume, so returning to the
    // foreground never restarts the timer or physics on its own.
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onAppLifecycleStateChanged,
    );
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        context.read<LevelPlayCubit>().pause();
      case AppLifecycleState.resumed:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _simulation?.dispose();
    _controller.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onSceneReady() {
    if (!mounted || _isSceneReady) return;
    setState(() => _isSceneReady = true);
  }

  void _onStart(LevelPlayCubit cubit) {
    _controller.calibrate();
    cubit.start();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LevelPlayCubit>();
    return BlocConsumer<LevelPlayCubit, LevelPlayState>(
      // Retry moves Won back to Ready without recreating the simulation, so
      // the marble must be explicitly respawned to the start; a fresh load
      // never reaches here with a simulation already built.
      listener: (context, state) {
        if (state is LevelPlayReady) _simulation?.respawn();
      },
      builder: (context, state) => switch (state) {
        LevelPlayLoading() => const LevelPlayLoadingView(),
        LevelPlayReady(:final level) => LevelPlayView(
          boardView: widget.boardBuilder(
            level: level,
            simulation: _simulationForPlay,
            isSimulationActive: false,
            controller: _controller,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
            onSceneReady: _onSceneReady,
          ),
          overlay: _isSceneReady
              ? LevelPlayReadyOverlay(onStart: () => _onStart(cubit))
              : const LevelPlayLoadingView(),
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
            controller: _controller,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
            onSceneReady: _onSceneReady,
          ),
          overlay: LevelPlayPlayingOverlay(
            cubit: cubit,
            title: level.title,
            controller: _controller,
            onPause: cubit.pause,
          ),
        ),
        // Also builds a BoardSceneView, the same as Playing and Falling
        // above, so its ticker and fall-in-progress state survive the
        // pause: the board freezes rather than being torn down and rebuilt.
        LevelPlayPaused(:final level) => LevelPlayView(
          boardView: widget.boardBuilder(
            level: level,
            simulation: _simulationForPlay,
            isSimulationActive: false,
            controller: _controller,
            onMarbleFell: cubit.marbleFell,
            onMarbleRespawned: cubit.marbleRespawned,
            onReachedExit: cubit.marbleReachedExit,
            onSceneReady: _onSceneReady,
          ),
          overlay: LevelPlayPausedOverlay(
            onResume: cubit.resume,
            onBackToLevels: widget.onExitToLevels,
          ),
        ),
        LevelPlayWon(
          :final level,
          :final time,
          :final par,
          :final bestTime,
          :final isNewBest,
          :final nextLevelId,
        ) =>
          LevelPlayView(
            boardView: widget.boardBuilder(
              level: level,
              simulation: _simulationForPlay,
              isSimulationActive: false,
              controller: _controller,
              onMarbleFell: cubit.marbleFell,
              onMarbleRespawned: cubit.marbleRespawned,
              onReachedExit: cubit.marbleReachedExit,
              onSceneReady: _onSceneReady,
            ),
            overlay: LevelPlayWonOverlay(
              time: time,
              par: par,
              bestTime: bestTime,
              isNewBest: isNewBest,
              onNext: nextLevelId == null
                  ? null
                  : () => widget.onNextLevel(nextLevelId),
              onRetry: cubit.retry,
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
