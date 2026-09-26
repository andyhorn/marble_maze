/// Localized strings for all UI copy: the generated [AppLocalizations] and a
/// `context.l10n` extension to read it.
library;

import 'package:flutter/widgets.dart';
import 'package:localizations/src/l10n/gen/app_localizations.dart';

export 'src/l10n/gen/app_localizations.dart';

/// Reads the app's localized strings from [BuildContext].
extension AppLocalizationsX on BuildContext {
  /// The current locale's [AppLocalizations].
  AppLocalizations get l10n => AppLocalizations.of(this);
}
