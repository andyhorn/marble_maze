import 'package:meta/meta.dart';

/// The bubble level's reading: how far the device is tilted from flat.
@immutable
class BubbleLevelState {
  /// Creates a bubble level state.
  const new({this.xAngle = 0, this.yAngle = 0, this.hasReading = false});

  /// The tilt about the screen's vertical axis, in radians. Positive means
  /// the right edge is higher than the left.
  final double xAngle;

  /// The tilt about the screen's horizontal axis, in radians. Positive
  /// means the top edge is higher than the bottom.
  final double yAngle;

  /// Whether any accelerometer reading has arrived yet.
  final bool hasReading;

  @override
  bool operator ==(Object other) =>
      other is BubbleLevelState &&
      other.xAngle == xAngle &&
      other.yAngle == yAngle &&
      other.hasReading == hasReading;

  @override
  int get hashCode => Object.hash(xAngle, yAngle, hasReading);
}
