import 'package:level_presentation/level_select/cubit/level_list_entry.dart';
import 'package:meta/meta.dart';

/// The level select screen's state.
@immutable
sealed class LevelSelectState {
  const new();
}

/// The manifest and saved records are being fetched.
class LevelSelectLoading extends LevelSelectState {
  /// Creates a loading state.
  const new();
}

/// The manifest and saved records loaded successfully. [entries] lists
/// every level in manifest order.
class LevelSelectLoaded extends LevelSelectState {
  /// Creates a loaded state for [entries].
  const new(this.entries);

  /// Every level in the manifest, in order, with its saved progress.
  final List<LevelListEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is LevelSelectLoaded && _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hashAll(entries);
}

/// The manifest or saved records failed to load.
class LevelSelectError extends LevelSelectState {
  /// Creates an error state.
  const new();
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
