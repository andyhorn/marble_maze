import 'dart:convert';

import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:test/test.dart';

const _levelOneText = '''
# title: Level One
# par: 10
###
#S#
#E#
###''';

const _levelTwoText = '''
# title: Level Two
###
#S#
#E#
###''';

void main() {
  group('LevelsRepository', () {
    late int loadCount;
    late LevelsRepository repository;

    Future<String> loader(String path) async {
      loadCount++;
      if (path == '${kLevelAssetPrefix}levels.json') {
        return json.encode(['level_one', 'level_two']);
      }
      if (path == '${kLevelAssetPrefix}level_one.txt') return _levelOneText;
      if (path == '${kLevelAssetPrefix}level_two.txt') return _levelTwoText;
      throw ArgumentError('Unexpected path: $path');
    }

    setUp(() {
      loadCount = 0;
      repository = LevelsRepository(
        dataSource: AssetLevelDataSource(loader: loader),
      );
    });

    test('getManifest returns an entry per listed level, in order', () async {
      final manifest = await repository.getManifest();

      expect(manifest, [
        const LevelManifestEntry(
          id: 'level_one',
          title: 'Level One',
          par: Duration(seconds: 10),
        ),
        const LevelManifestEntry(id: 'level_two', title: 'Level Two'),
      ]);
    });

    test('getLevel returns the full parsed level', () async {
      final level = await repository.getLevel('level_one');

      expect(level.id, 'level_one');
      expect(level.title, 'Level One');
    });

    test('getLevel throws for an id not in the manifest', () async {
      expect(
        () => repository.getLevel('unknown'),
        throwsA(isA<LevelNotFoundException>()),
      );
    });

    test('caches a level after its first load', () async {
      await repository.getLevel('level_one');
      final countAfterFirst = loadCount;

      await repository.getLevel('level_one');

      expect(loadCount, countAfterFirst);
    });
  });
}
