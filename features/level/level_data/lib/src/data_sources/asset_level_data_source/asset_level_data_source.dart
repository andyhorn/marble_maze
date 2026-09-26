import 'dart:convert';

/// The asset key prefix every level asset is bundled under.
///
/// Declared by this package's `pubspec.yaml` `flutter: assets:` entry, so
/// the app (a Flutter package) resolves them as `packages/level_data/...`.
const kLevelAssetPrefix = 'packages/level_data/assets/levels/';

/// Reads the levels manifest and level text files through an injected
/// loader, keeping this package pure Dart. The app passes
/// `rootBundle.loadString`.
class AssetLevelDataSource {
  /// Creates a data source backed by [loader].
  const new({required this.loader});

  /// Reads the text at an asset path.
  final Future<String> Function(String path) loader;

  /// Loads and decodes `levels.json`, returning the ordered list of level
  /// ids it lists.
  Future<List<String>> loadManifestIds() async {
    final text = await loader('${kLevelAssetPrefix}levels.json');
    final decoded = json.decode(text);
    return (decoded as List<Object?>).cast<String>();
  }

  /// Loads the raw text of the level file for [id].
  Future<String> loadLevelText(String id) =>
      loader('$kLevelAssetPrefix$id.txt');

  /// The file name (with extension) the level file for [id] is stored
  /// under, for use in level format error locations.
  String fileNameFor(String id) => '$id.txt';
}
