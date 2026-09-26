import 'package:level_domain/src/level.dart';
import 'package:level_domain/src/level_manifest_entry.dart';

/// Loads level metadata and full levels.
abstract interface class ILevelsRepository {
  /// Returns every level's manifest entry, in the manifest's order.
  Future<List<LevelManifestEntry>> getManifest();

  /// Returns the full level for [id].
  ///
  /// Throws a `LevelNotFoundException` if [id] is not in the manifest, or a
  /// `LevelFormatException` if the level file fails to parse.
  Future<Level> getLevel(String id);
}
