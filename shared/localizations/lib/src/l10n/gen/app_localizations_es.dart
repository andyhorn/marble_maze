// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Laberinto de canicas';

  @override
  String get levelPlayTapToStart => 'Toca para empezar';

  @override
  String get levelPlayErrorMessage => 'No se pudo cargar este nivel.';

  @override
  String get backToLevels => 'Volver a los niveles';

  @override
  String levelPlayWonTimeLabel(String time) {
    return 'Tiempo: $time';
  }

  @override
  String levelPlayWonParLabel(String time) {
    return 'Par: $time';
  }

  @override
  String get homePlayFirstRoll => 'Jugar Primera Vuelta';

  @override
  String get levelPlayDragToTiltHint => 'Arrastra para inclinar';
}
