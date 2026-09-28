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
  String levelPlayWonBestLabel(String time) {
    return 'Best: $time';
  }

  @override
  String get levelPlayWonNewBestBadge => 'New best!';

  @override
  String get levelPlayWonNext => 'Next';

  @override
  String get levelPlayWonRetry => 'Retry';

  @override
  String get levelSelectTitle => 'Levels';

  @override
  String get levelSelectErrorMessage => 'Levels could not be loaded.';

  @override
  String levelSelectBestTimeLabel(String time) {
    return 'Best: $time';
  }

  @override
  String get levelSelectNoBestTime => 'No best time yet';

  @override
  String get levelSelectParBeaten => 'Par beaten';

  @override
  String get levelSelectParNotBeaten => 'Par not beaten';

  @override
  String get levelSelectParNone => 'No par time';

  @override
  String get levelPlayDragToTiltHint => 'Drag to tilt';

  @override
  String get levelPlayPause => 'Pause';

  @override
  String get levelPlayPausedTitle => 'Paused';

  @override
  String get levelPlayResume => 'Resume';

  @override
  String get unsupportedDeviceTitle => 'This device isn\'t supported';

  @override
  String get unsupportedDeviceMessage => 'Marble Maze needs graphics hardware this device doesn\'t have.';

  @override
  String get bubbleLevelTooltip => 'Bubble level';

  @override
  String get bubbleLevelTitle => 'Bubble level';

  @override
  String get bubbleLevelWaiting => 'Waiting for the accelerometer…';
}
