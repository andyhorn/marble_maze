/// Tuning constants for `TouchTiltMapper`.
class TouchTiltConfig {
  /// Creates a touch tilt config.
  const new({
    this.fullTiltDistance = 120,
    this.easeDuration = const Duration(milliseconds: 250),
  });

  /// The default tuning.
  static const TouchTiltConfig standard = TouchTiltConfig();

  /// The drag distance, in logical pixels, that reaches full tilt.
  final double fullTiltDistance;

  /// How long it takes to ease back to flat after release.
  final Duration easeDuration;
}
