/// Reads and saves the player's settings.
///
/// A storage failure never throws to callers: it is logged, reads fall back
/// to the default, and writes are dropped.
abstract interface class ISettingsRepository {
  /// Whether tilt input is calibrated to the angle the device is held at
  /// when a level starts, rather than measured from flat.
  ///
  /// Defaults to true, including when nothing is saved or reading fails.
  Future<bool> getCalibrateTilt();

  /// Saves whether tilt input calibrates to the held angle.
  Future<void> setCalibrateTilt({required bool value});

  /// Whether the bubble level is shown in the corner while playing.
  ///
  /// Defaults to true, including when nothing is saved or reading fails.
  Future<bool> getShowBubbleLevel();

  /// Saves whether the bubble level is shown while playing.
  Future<void> setShowBubbleLevel({required bool value});
}
