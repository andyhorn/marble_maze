import 'package:flutter/widgets.dart';
import 'package:marble_maze_app/l10n/gen/app_localizations.dart';

export 'package:marble_maze_app/l10n/gen/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
