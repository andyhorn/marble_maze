import 'package:level_domain/level_domain.dart';
import 'package:meta/meta.dart';

/// The level play screen's state.
///
/// Ready/Won/Paused states are added alongside the gameplay features that
/// produce them.
@immutable
sealed class LevelPlayState {
  const new();
}

/// The level is being fetched from the repository.
class LevelPlayLoading extends LevelPlayState {
  /// Creates a loading state.
  const new();
}

/// The level loaded successfully and is ready to render and simulate.
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
/// [LevelPlayPlaying].
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

/// The level failed to load, for example an unknown level id.
class LevelPlayError extends LevelPlayState {
  /// Creates an error state.
  const new();
}
