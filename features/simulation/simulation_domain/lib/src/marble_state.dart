import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';

/// A snapshot of the marble's physical state.
@immutable
class MarbleState {
  /// Creates a marble state.
  const new({
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.isActive,
  });

  /// The marble's world-space position.
  final Vector3 position;

  /// The marble's world-space orientation.
  final Quaternion rotation;

  /// The marble's linear velocity.
  final Vector3 velocity;

  /// Whether the marble is being simulated. False while sinking into a hole
  /// or after reaching the exit.
  final bool isActive;
}
