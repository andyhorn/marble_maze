import 'package:flutter_test/flutter_test.dart';
import 'package:settings_data_shared_preferences/settings_data_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesSettingsRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('calibrates tilt by default', () async {
      expect(
        await SharedPreferencesSettingsRepository().getCalibrateTilt(),
        isTrue,
      );
    });

    test('returns the saved calibrate tilt setting', () async {
      final repository = SharedPreferencesSettingsRepository();

      await repository.setCalibrateTilt(value: false);

      expect(await repository.getCalibrateTilt(), isFalse);
    });

    test('falls back to the default when preferences fail', () async {
      final repository = SharedPreferencesSettingsRepository(
        preferences: () async => throw Exception('no storage'),
      );

      expect(await repository.getCalibrateTilt(), isTrue);
      await repository.setCalibrateTilt(value: false);
    });
  });
}
