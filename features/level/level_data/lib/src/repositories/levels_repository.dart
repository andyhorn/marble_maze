import 'package:level_data/src/data_sources/asset_level_data_source/asset_level_data_source.dart';
import 'package:level_data/src/mappers/level_text_parser.dart';
import 'package:level_domain/level_domain.dart';

/// An [ILevelsRepository] backed by [AssetLevelDataSource] and
/// [LevelTextParser], caching parsed levels once loaded.
class LevelsRepository implements ILevelsRepository {
  /// Creates a levels repository over [dataSource].
  new({required this.dataSource}) : _parser = LevelTextParser();

  /// The data source this repository reads level assets through.
  final AssetLevelDataSource dataSource;

  final LevelTextParser _parser;
  final Map<String, Level> _cache = {};

  @override
  Future<List<LevelManifestEntry>> getManifest() async {
    final ids = await dataSource.loadManifestIds();
    final entries = <LevelManifestEntry>[];
    for (final id in ids) {
      final level = await _levelFor(id);
      entries.add(
        LevelManifestEntry(id: level.id, title: level.title, par: level.par),
      );
    }
    return entries;
  }

  @override
  Future<Level> getLevel(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    final ids = await dataSource.loadManifestIds();
    if (!ids.contains(id)) throw LevelNotFoundException(id);
    return await _levelFor(id);
  }

  Future<Level> _levelFor(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    final text = await dataSource.loadLevelText(id);
    final level = _parser.parse(text, fileName: dataSource.fileNameFor(id));
    _cache[id] = level;
    return level;
  }
}
