/// No level with [id] exists in the manifest.
class LevelNotFoundException implements Exception {
  /// Creates a level-not-found exception for [id].
  const new(this.id);

  /// The unknown level id.
  final String id;

  @override
  String toString() => 'LevelNotFoundException: no level with id "$id"';
}
