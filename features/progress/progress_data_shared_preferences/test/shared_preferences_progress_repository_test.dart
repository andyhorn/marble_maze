import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_data_shared_preferences/progress_data_shared_preferences.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences;

void main() {
  group('SharedPreferencesProgressRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    SharedPreferencesProgressRepository build() =>
        SharedPreferencesProgressRepository();

    test('getRecords returns an empty map when nothing is saved', () async {
      final repository = build();

      final records = await repository.getRecords();

      expect(records, isEmpty);
    });

    test('submitTime saves the first time as a new best', () async {
      final repository = build();

      final isNewBest = await repository.submitTime(
        'first_roll',
        const Duration(seconds: 20),
      );

      expect(isNewBest, isTrue);
      final records = await repository.getRecords();
      expect(
        records['first_roll'],
        const LevelRecord(
          levelId: 'first_roll',
          bestTime: Duration(seconds: 20),
        ),
      );
    });

    test('submitTime with a faster time is a new best', () async {
      final repository = build();
      await repository.submitTime('first_roll', const Duration(seconds: 20));

      final isNewBest = await repository.submitTime(
        'first_roll',
        const Duration(seconds: 15),
      );

      expect(isNewBest, isTrue);
      final records = await repository.getRecords();
      expect(records['first_roll']!.bestTime, const Duration(seconds: 15));
    });

    test('submitTime with a slower time is not a new best', () async {
      final repository = build();
      await repository.submitTime('first_roll', const Duration(seconds: 20));

      final isNewBest = await repository.submitTime(
        'first_roll',
        const Duration(seconds: 25),
      );

      expect(isNewBest, isFalse);
      final records = await repository.getRecords();
      expect(records['first_roll']!.bestTime, const Duration(seconds: 20));
    });

    test('submitTime with an equal time is not a new best', () async {
      final repository = build();
      await repository.submitTime('first_roll', const Duration(seconds: 20));

      final isNewBest = await repository.submitTime(
        'first_roll',
        const Duration(seconds: 20),
      );

      expect(isNewBest, isFalse);
    });

    test('records for different levels are independent', () async {
      final repository = build();
      await repository.submitTime('first_roll', const Duration(seconds: 20));
      await repository.submitTime('second_roll', const Duration(seconds: 30));

      final records = await repository.getRecords();

      expect(records['first_roll']!.bestTime, const Duration(seconds: 20));
      expect(records['second_roll']!.bestTime, const Duration(seconds: 30));
    });

    test('a fresh repository reads what an earlier one saved', () async {
      final first = build();
      await first.submitTime('first_roll', const Duration(seconds: 20));

      final second = build();
      final records = await second.getRecords();

      expect(records['first_roll']!.bestTime, const Duration(seconds: 20));
    });

    group('storage failures', () {
      test('getRecords logs and returns an empty map', () async {
        final repository = SharedPreferencesProgressRepository(
          preferences: () => throw Exception('boom'),
        );

        final records = await repository.getRecords();

        expect(records, isEmpty);
      });

      test('submitTime logs and returns false, never throwing', () async {
        final repository = SharedPreferencesProgressRepository(
          preferences: () => throw Exception('boom'),
        );

        final isNewBest = await repository.submitTime(
          'first_roll',
          const Duration(seconds: 20),
        );

        expect(isNewBest, isFalse);
      });

      test('a false setInt result is reported as not a new best', () async {
        final preferences = _MockSharedPreferences();
        when(preferences.getKeys).thenReturn(<String>{});
        when(() => preferences.getInt(any())).thenReturn(null);
        when(() => preferences.setInt(any(), any()))
            .thenAnswer((_) async => false);
        final repository = SharedPreferencesProgressRepository(
          preferences: () async => preferences,
        );

        final isNewBest = await repository.submitTime(
          'first_roll',
          const Duration(seconds: 20),
        );

        expect(isNewBest, isFalse);
      });
    });
  });
}
