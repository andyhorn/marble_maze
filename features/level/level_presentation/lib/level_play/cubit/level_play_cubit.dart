import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';
import 'package:progress_domain/progress_domain.dart';

/// Loads a level by id and drives it through ready, playing, falling, and
/// won, exposing each step as a [LevelPlayState].
class LevelPlayCubit extends Cubit<LevelPlayState> {
  /// Creates a level play cubit over [repository] and [progressRepository].
  ///
  /// [stopwatchFactory] builds the [Stopwatch] [start] uses to time the
  /// level; tests inject a fake for deterministic elapsed times.
  new({
    required this.repository,
    required this.progressRepository,
    Stopwatch Function() stopwatchFactory = Stopwatch.new,
  }) : // External name stopwatchFactory is clearer at call sites than the
       // private field it initializes.
       // ignore: prefer_initializing_formals
       _stopwatchFactory = stopwatchFactory,
       super(const LevelPlayLoading());

  /// The repository this cubit loads levels through.
  final ILevelsRepository repository;

  /// The repository this cubit reads and saves best times through.
  final IProgressRepository progressRepository;

  final Stopwatch Function() _stopwatchFactory;
  Stopwatch? _stopwatch;
  List<LevelManifestEntry> _manifest = [];
  final Map<String, Duration> _bestTimes = {};

  /// The time elapsed since [start], or zero before it is called.
  Duration get elapsed => _stopwatch?.elapsed ?? Duration.zero;

  /// Loads the level with [levelId], emitting [LevelPlayReady] on success or
  /// [LevelPlayError] if it fails, for example an unknown id.
  ///
  /// Also loads the manifest (to find the next level) and the player's
  /// saved records (to know the current best time). Either failing degrades
  /// rather than blocking play: no next level, no prior best.
  Future<void> load(String levelId) async {
    emit(const LevelPlayLoading());
    try {
      final level = await repository.getLevel(levelId);
      await _loadManifest();
      await _loadBestTimes();
      emit(LevelPlayReady(level));
    } on Exception {
      emit(const LevelPlayError());
    }
  }

  Future<void> _loadManifest() async {
    try {
      _manifest = await repository.getManifest();
    } on Exception {
      _manifest = [];
    }
  }

  Future<void> _loadBestTimes() async {
    try {
      final records = await progressRepository.getRecords();
      _bestTimes.addAll({
        for (final entry in records.entries) entry.key: entry.value.bestTime,
      });
    } on Exception {
      // Keep whatever best times were already cached.
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
  ///
  /// The new best time is computed from the cached records loaded in
  /// [load], so [LevelPlayWon] is emitted immediately; saving it through
  /// [progressRepository] happens in the background and never delays this
  /// state.
  void marbleReachedExit() {
    final current = state;
    if (current is! LevelPlayPlaying) return;
    _stopwatch?.stop();
    final level = current.level;
    final time = elapsed;
    final previousBest = _bestTimes[level.id];
    final isNewBest = previousBest == null || time < previousBest;
    if (isNewBest) _bestTimes[level.id] = time;
    emit(
      LevelPlayWon(
        level: level,
        time: time,
        par: level.par,
        bestTime: isNewBest ? time : previousBest,
        isNewBest: isNewBest,
        nextLevelId: _nextLevelId(level.id),
      ),
    );
    unawaited(progressRepository.submitTime(level.id, time));
  }

  String? _nextLevelId(String levelId) {
    final index = _manifest.indexWhere((entry) => entry.id == levelId);
    if (index == -1 || index + 1 >= _manifest.length) return null;
    return _manifest[index + 1].id;
  }

  /// Moves from [LevelPlayWon] back to [LevelPlayReady], so the player can
  /// try the same level again. Ignored in any other state.
  void retry() {
    final current = state;
    if (current is! LevelPlayWon) return;
    emit(LevelPlayReady(current.level));
  }
}
