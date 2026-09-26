import 'package:flutter_test/flutter_test.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Test helpers for pumping widgets that read localized strings.
extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a [MaterialApp] with the localizations
  /// delegates every level play widget test needs, since they read strings
  /// through `context.l10n`.
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
  }
}
