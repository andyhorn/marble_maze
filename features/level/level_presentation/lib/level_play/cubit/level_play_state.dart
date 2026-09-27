import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';

/// The level play screen's state.
@immutable
sealed class LevelPlayState {
  const new();
}

/// The level is being fetched from the repository.
class LevelPlayLoading extends LevelPlayState {
  /// Creates a loading state.
  const new();
}

/// The level loaded successfully. The board is shown and the marble sits
/// still at the start, waiting for the player to tap to start the timer.
class LevelPlayReady extends LevelPlayState {
  /// Creates a ready state for [level].
  const new(this.level);

  /// The loaded level.
  final Level level;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayReady && other.level == level;

  @override
  int get hashCode => level.hashCode;
}

/// The timer is running and the marble is rolling.
class LevelPlayPlaying extends LevelPlayState {
  /// Creates a playing state for [level].
  const new(this.level);

  /// The loaded level.
  final Level level;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayPlaying && other.level == level;

  @override
  int get hashCode => level.hashCode;
}

/// The marble fell into a hole or left the board and is sinking. [level]
/// keeps the board on screen during the fall, the same as
/// [LevelPlayPlaying]. The timer keeps running.
class LevelPlayFalling extends LevelPlayState {
  /// Creates a falling state for [level].
  const new(this.level);

  /// The loaded level.
  final Level level;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayFalling && other.level == level;

  @override
  int get hashCode => level.hashCode;
}

/// Paused, either by the pause button or automatically when the app goes to
/// the background. [level] keeps the board on screen while paused, the same
/// as [LevelPlayPlaying] and [LevelPlayFalling]. The timer is stopped.
///
/// [resumeTo] is the [LevelPlayPlaying] or [LevelPlayFalling] state this
/// paused from, restored on resume.
class LevelPlayPaused extends LevelPlayState {
  /// Creates a paused state for [level], resuming to [resumeTo].
  const new({required this.level, required this.resumeTo});

  /// The loaded level.
  final Level level;

  /// The state to return to on resume: either [LevelPlayPlaying] or
  /// [LevelPlayFalling].
  final LevelPlayState resumeTo;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayPaused &&
      other.level == level &&
      other.resumeTo == resumeTo;

  @override
  int get hashCode => Object.hash(level, resumeTo);
}

/// The marble reached the exit. The timer has stopped at [time]; [par] is
/// the level's par time, if it has one. [bestTime] is the best time saved
/// for this level, including this run; [isNewBest] is whether this run set
/// it. [nextLevelId] is the next level in the manifest, or null on the
/// last level.
class LevelPlayWon extends LevelPlayState {
  /// Creates a won state for [level], finished in [time].
  const new({
    required this.level,
    required this.time,
    required this.par,
    required this.bestTime,
    required this.isNewBest,
    required this.nextLevelId,
  });

  /// The loaded level.
  final Level level;

  /// The time elapsed from start to exit.
  final Duration time;

  /// The level's par time, if it has one.
  final Duration? par;

  /// The best time saved for this level, including this run.
  final Duration bestTime;

  /// Whether this run set a new best time.
  final bool isNewBest;

  /// The next level's id in the manifest, or null if [level] is the last.
  final String? nextLevelId;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayWon &&
      other.level == level &&
      other.time == time &&
      other.par == par &&
      other.bestTime == bestTime &&
      other.isNewBest == isNewBest &&
      other.nextLevelId == nextLevelId;

  @override
  int get hashCode =>
      Object.hash(level, time, par, bestTime, isNewBest, nextLevelId);
}

/// The level failed to load, for example an unknown level id.
class LevelPlayError extends LevelPlayState {
  /// Creates an error state.
  const new();
}
