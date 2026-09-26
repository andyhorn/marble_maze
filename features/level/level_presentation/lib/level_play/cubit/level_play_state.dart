import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';

/// The level play screen's state.
///
/// Paused is added alongside the pause feature that produces it.
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

/// The marble reached the exit. The timer has stopped at [time]; [par] is
/// the level's par time, if it has one.
class LevelPlayWon extends LevelPlayState {
  /// Creates a won state for [level], finished in [time].
  const new(this.level, this.time, this.par);

  /// The loaded level.
  final Level level;

  /// The time elapsed from start to exit.
  final Duration time;

  /// The level's par time, if it has one.
  final Duration? par;

  @override
  bool operator ==(Object other) =>
      other is LevelPlayWon &&
      other.level == level &&
      other.time == time &&
      other.par == par;

  @override
  int get hashCode => Object.hash(level, time, par);
}

/// The level failed to load, for example an unknown level id.
class LevelPlayError extends LevelPlayState {
  /// Creates an error state.
  const new();
}
