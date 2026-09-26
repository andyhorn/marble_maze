import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  test('a sphere dropped onto a static floor falls and comes to rest', () {
    final world = Box3dWorld(gravity: Vector3(0, -9.81, 0));
    addTearDown(world.dispose);

    world
        .createBody(type: Box3dBodyType.static_, position: Vector3(0, -0.5, 0))
        .addBox(Vector3(10, 0.5, 10));

    final marble = world.createBody(position: Vector3(0, 3, 0))..addSphere(0.3);

    for (var i = 0; i < 240; i++) {
      world.step(1 / 120);
    }

    expect(marble.position.y, closeTo(0.3, 0.05));
    expect(marble.linearVelocity.length, lessThan(0.1));
  });
}
