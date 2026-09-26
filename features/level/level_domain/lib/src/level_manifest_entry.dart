import 'package:meta/meta.dart';

/// A level's entry in the manifest: enough to list it before it is loaded.
@immutable
class LevelManifestEntry {
  /// Creates a manifest entry.
  const new({required this.id, required this.title, this.par});

  /// The level's unique id (the level file's name without its extension).
  final String id;

  /// The level's display title.
  final String title;

  /// An optional par time for the level.
  final Duration? par;

  @override
  bool operator ==(Object other) =>
      other is LevelManifestEntry &&
      other.id == id &&
      other.title == title &&
      other.par == par;

  @override
  int get hashCode => Object.hash(id, title, par);

  @override
  String toString() => 'LevelManifestEntry(id: $id, title: $title)';
}
