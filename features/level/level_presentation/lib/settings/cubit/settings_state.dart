import 'package:meta/meta.dart';

/// The player's settings as shown on the settings screen.
@immutable
class SettingsState {
  /// Creates a settings state.
  const new({this.calibrateTilt = true});

  /// Whether tilt input calibrates to the angle the device is held at.
  final bool calibrateTilt;

  @override
  bool operator ==(Object other) =>
      other is SettingsState && other.calibrateTilt == calibrateTilt;

  @override
  int get hashCode => calibrateTilt.hashCode;
}
