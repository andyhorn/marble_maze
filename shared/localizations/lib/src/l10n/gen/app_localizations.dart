// dart format off
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The name of the app
  ///
  /// In en, this message translates to:
  /// **'Marble Maze'**
  String get appTitle;

  /// Shown over the board before the player starts a level
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get levelPlayTapToStart;

  /// Shown when a level fails to load
  ///
  /// In en, this message translates to:
  /// **'This level could not be loaded.'**
  String get levelPlayErrorMessage;

  /// Button that returns to level select
  ///
  /// In en, this message translates to:
  /// **'Back to levels'**
  String get backToLevels;

  /// The player's finishing time on the win overlay
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String levelPlayWonTimeLabel(String time);

  /// The level's par time on the win overlay
  ///
  /// In en, this message translates to:
  /// **'Par: {time}'**
  String levelPlayWonParLabel(String time);

  /// The level's best saved time on the win overlay
  ///
  /// In en, this message translates to:
  /// **'Best: {time}'**
  String levelPlayWonBestLabel(String time);

  /// Badge shown on the win overlay when this run set a new best time
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get levelPlayWonNewBestBadge;

  /// Button on the win overlay that opens the next level
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get levelPlayWonNext;

  /// Button on the win overlay that replays the same level
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get levelPlayWonRetry;

  /// The level select screen's title
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelSelectTitle;

  /// Shown when the level manifest fails to load
  ///
  /// In en, this message translates to:
  /// **'Levels could not be loaded.'**
  String get levelSelectErrorMessage;

  /// A level's best saved time in the level list
  ///
  /// In en, this message translates to:
  /// **'Best: {time}'**
  String levelSelectBestTimeLabel(String time);

  /// Shown in the level list when a level has no saved best time
  ///
  /// In en, this message translates to:
  /// **'No best time yet'**
  String get levelSelectNoBestTime;

  /// Shown in the level list when the player's best time beats par
  ///
  /// In en, this message translates to:
  /// **'Par beaten'**
  String get levelSelectParBeaten;

  /// Shown in the level list when the player has not yet beaten par
  ///
  /// In en, this message translates to:
  /// **'Par not beaten'**
  String get levelSelectParNotBeaten;

  /// Shown in the level list when a level has no par time
  ///
  /// In en, this message translates to:
  /// **'No par time'**
  String get levelSelectParNone;

  /// One-time hint shown when the accelerometer is unavailable, so the player knows to drag the board instead
  ///
  /// In en, this message translates to:
  /// **'Drag to tilt'**
  String get levelPlayDragToTiltHint;

  /// Tooltip and semantics label for the HUD's pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get levelPlayPause;

  /// Title shown on the paused overlay
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get levelPlayPausedTitle;

  /// Button on the paused overlay that resumes the level
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get levelPlayResume;

  /// Title shown at startup when Flutter GPU is unavailable
  ///
  /// In en, this message translates to:
  /// **'This device isn\'t supported'**
  String get unsupportedDeviceTitle;

  /// Message shown at startup when Flutter GPU is unavailable
  ///
  /// In en, this message translates to:
  /// **'Marble Maze needs graphics hardware this device doesn\'t have.'**
  String get unsupportedDeviceMessage;

  /// Tooltip of the level select button that opens the bubble level
  ///
  /// In en, this message translates to:
  /// **'Bubble level'**
  String get bubbleLevelTooltip;

  /// Title of the bubble level screen
  ///
  /// In en, this message translates to:
  /// **'Bubble level'**
  String get bubbleLevelTitle;

  /// Shown on the bubble level screen until the first accelerometer reading arrives
  ///
  /// In en, this message translates to:
  /// **'Waiting for the accelerometer…'**
  String get bubbleLevelWaiting;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
