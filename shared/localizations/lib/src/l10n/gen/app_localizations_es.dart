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
  String levelPlayWonBestLabel(String time) {
    return 'Mejor: $time';
  }

  @override
  String get levelPlayWonNewBestBadge => '¡Nuevo mejor tiempo!';

  @override
  String get levelPlayWonNext => 'Siguiente';

  @override
  String get levelPlayWonRetry => 'Reintentar';

  @override
  String get levelSelectTitle => 'Niveles';

  @override
  String get levelSelectErrorMessage => 'No se pudieron cargar los niveles.';

  @override
  String levelSelectBestTimeLabel(String time) {
    return 'Mejor: $time';
  }

  @override
  String get levelSelectNoBestTime => 'Sin mejor tiempo aún';

  @override
  String get levelSelectParBeaten => 'Par superado';

  @override
  String get levelSelectParNotBeaten => 'Par no superado';

  @override
  String get levelSelectParNone => 'Sin tiempo par';

  @override
  String get levelPlayDragToTiltHint => 'Arrastra para inclinar';

  @override
  String get levelPlayPause => 'Pausa';

  @override
  String get levelPlayPausedTitle => 'En pausa';

  @override
  String get levelPlayResume => 'Reanudar';

  @override
  String get unsupportedDeviceTitle => 'Este dispositivo no es compatible';

  @override
  String get unsupportedDeviceMessage => 'Laberinto de canicas necesita hardware gráfico que este dispositivo no tiene.';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsCalibrateTiltTitle => 'Calibrar según cómo sostengo el dispositivo';

  @override
  String get settingsCalibrateTiltSubtitle => 'Desactivado mide la inclinación desde la horizontal, así que juega con el dispositivo plano.';

  @override
  String get settingsBubbleLevel => 'Nivel de burbuja';

  @override
  String get bubbleLevelTitle => 'Nivel de burbuja';

  @override
  String get bubbleLevelWaiting => 'Esperando al acelerómetro…';

  @override
  String get settingsShowBubbleLevelTitle => 'Mostrar el nivel de burbuja al jugar';

  @override
  String get settingsShowBubbleLevelSubtitle => 'Un pequeño nivel en la esquina que muestra la inclinación del tablero.';
}
