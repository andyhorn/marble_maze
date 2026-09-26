import 'package:box3d/box3d.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  setUpAll(Box3d.ensureInitialized);

  const marbleRadius = 0.3;
  const timeStep = 1 / 120;
  const twoSecondsOfSteps = 240;

  test('a sphere dropped onto a static floor falls and comes to rest', () {
    final world = Box3dWorld(gravity: Vector3(0, -9.81, 0));
    addTearDown(world.dispose);

    world
        .createBody(type: Box3dBodyType.static_, position: Vector3(0, -0.5, 0))
        .addBox(Vector3(10, 0.5, 10));

    final marble = world.createBody(position: Vector3(0, 3, 0))
      ..addSphere(marbleRadius);

    for (var i = 0; i < twoSecondsOfSteps; i++) {
      world.step(timeStep);
    }

    expect(marble.position.y, closeTo(marbleRadius, 0.05));
    expect(marble.linearVelocity.length, lessThan(0.1));
  });
}
