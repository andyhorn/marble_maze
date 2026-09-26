import 'dart:convert';

import 'package:level_data/level_data.dart';
import 'package:test/test.dart';

Future<String> _fakeLoader(String path) async {
  if (path == '${kLevelAssetPrefix}levels.json') {
    return json.encode(['first_roll', 'second']);
  }
  if (path == '${kLevelAssetPrefix}first_roll.txt') {
    return '# title: First Roll\n###\n#S#\n#E#\n###';
  }
  throw ArgumentError('Unexpected path: $path');
}

void main() {
  group('AssetLevelDataSource', () {
    late AssetLevelDataSource dataSource;

    setUp(() {
      dataSource = const AssetLevelDataSource(loader: _fakeLoader);
    });

    test('loads and decodes the manifest ids', () async {
      final ids = await dataSource.loadManifestIds();
      expect(ids, ['first_roll', 'second']);
    });

    test("loads a level file's text", () async {
      final text = await dataSource.loadLevelText('first_roll');
      expect(text, contains('# title: First Roll'));
    });

    test('derives the file name from the id', () {
      expect(dataSource.fileNameFor('first_roll'), 'first_roll.txt');
    });
  });
}
