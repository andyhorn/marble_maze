// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Marble Maze';

  @override
  String get levelPlayTapToStart => 'Tap to start';

  @override
  String get levelPlayErrorMessage => 'This level could not be loaded.';

  @override
  String get backToLevels => 'Back to levels';

  @override
  String levelPlayWonTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String levelPlayWonParLabel(String time) {
    return 'Par: $time';
  }

  @override
  String get homePlayFirstRoll => 'Play First Roll';

  @override
  String get levelPlayDragToTiltHint => 'Drag to tilt';
}
