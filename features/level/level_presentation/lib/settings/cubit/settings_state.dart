import 'package:meta/meta.dart';

/// The player's settings as shown on the settings screen.
@immutable
class SettingsState {
  /// Creates a settings state.
  const new({this.calibrateTilt = true, this.showBubbleLevel = true});

  /// Whether tilt input calibrates to the angle the device is held at.
  final bool calibrateTilt;

  /// Whether the bubble level is shown in the corner while playing.
  final bool showBubbleLevel;

  /// A copy of this state with the given fields replaced.
  SettingsState copyWith({bool? calibrateTilt, bool? showBubbleLevel}) =>
      SettingsState(
        calibrateTilt: calibrateTilt ?? this.calibrateTilt,
        showBubbleLevel: showBubbleLevel ?? this.showBubbleLevel,
      );

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      other.calibrateTilt == calibrateTilt &&
      other.showBubbleLevel == showBubbleLevel;

  @override
  int get hashCode => Object.hash(calibrateTilt, showBubbleLevel);
}
