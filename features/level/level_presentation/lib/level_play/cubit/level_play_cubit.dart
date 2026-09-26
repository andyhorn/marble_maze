import 'package:bloc/bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';

/// Loads a level by id and drives it through ready, playing, falling, and
/// won, exposing each step as a [LevelPlayState].
class LevelPlayCubit extends Cubit<LevelPlayState> {
  /// Creates a level play cubit over [repository].
  ///
  /// [stopwatchFactory] builds the [Stopwatch] [start] uses to time the
  /// level; tests inject a fake for deterministic elapsed times.
  new({
    required this.repository,
    Stopwatch Function() stopwatchFactory = Stopwatch.new,
  }) : // External name stopwatchFactory is clearer at call sites than the
       // private field it initializes.
       // ignore: prefer_initializing_formals
       _stopwatchFactory = stopwatchFactory,
       super(const LevelPlayLoading());

  /// The repository this cubit loads levels through.
  final ILevelsRepository repository;

  final Stopwatch Function() _stopwatchFactory;
  Stopwatch? _stopwatch;

  /// The time elapsed since [start], or zero before it is called.
  Duration get elapsed => _stopwatch?.elapsed ?? Duration.zero;

  /// Loads the level with [levelId], emitting [LevelPlayReady] on success or
  /// [LevelPlayError] if it fails, for example an unknown id.
  Future<void> load(String levelId) async {
    emit(const LevelPlayLoading());
    try {
      final level = await repository.getLevel(levelId);
      emit(LevelPlayReady(level));
    } on Exception {
      emit(const LevelPlayError());
    }
  }

  /// Moves from [LevelPlayReady] to [LevelPlayPlaying] and starts the
  /// timer. Ignored in any other state.
  void start() {
    final current = state;
    if (current is! LevelPlayReady) return;
    _stopwatch = _stopwatchFactory()..start();
    emit(LevelPlayPlaying(current.level));
  }

  /// Moves from [LevelPlayPlaying] to [LevelPlayFalling]. The timer keeps
  /// running: holes cost time, not lives. Ignored in any other state.
  void marbleFell() {
    final current = state;
    if (current is! LevelPlayPlaying) return;
    emit(LevelPlayFalling(current.level));
  }

  /// Moves from [LevelPlayFalling] back to [LevelPlayPlaying]. Ignored in
  /// any other state.
  void marbleRespawned() {
    final current = state;
    if (current is! LevelPlayFalling) return;
    emit(LevelPlayPlaying(current.level));
  }

  /// Moves from [LevelPlayPlaying] to [LevelPlayWon] and stops the timer.
  /// Ignored in any other state, including [LevelPlayFalling].
  void marbleReachedExit() {
    final current = state;
    if (current is! LevelPlayPlaying) return;
    _stopwatch?.stop();
    emit(LevelPlayWon(current.level, elapsed, current.level.par));
  }
}
