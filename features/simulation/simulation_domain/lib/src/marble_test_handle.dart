import 'package:vector_math/vector_math.dart';

/// A backend-supplied hook for placing the marble and setting its velocity
/// directly, bypassing normal physics. The marble simulation interface
/// itself has no test-only methods; backends implement this alongside it
/// for their own contract-test harness.
abstract interface class MarbleTestHandle {
  /// Teleports the marble to [position].
  void placeMarble(Vector3 position);

  /// Sets the marble's linear velocity directly.
  void setMarbleVelocity(Vector3 velocity);
}
