import 'dart:io';

import 'package:level_data/level_data.dart';
import 'package:test/test.dart';

/// Reads a bundled level asset straight off disk, stripping the
/// `packages/level_data/` prefix the app resolves through `rootBundle`.
///
/// `dart test` runs from this package's root, so the stripped path
/// resolves directly.
Future<String> _diskLoader(String path) {
  final relative = path.replaceFirst('packages/level_data/', '');
  return File(relative).readAsString();
}

void main() {
  test('every bundled level parses without error', () async {
    const dataSource = AssetLevelDataSource(loader: _diskLoader);
    final repository = LevelsRepository(dataSource: dataSource);

    final manifest = await repository.getManifest();

    expect(manifest, isNotEmpty);
    for (final entry in manifest) {
      final level = await repository.getLevel(entry.id);
      expect(level.id, entry.id);
    }
  });
}
