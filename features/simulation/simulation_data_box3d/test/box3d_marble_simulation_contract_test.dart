import 'package:box3d/box3d.dart';
import 'package:simulation_data_box3d/simulation_data_box3d.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:simulation_domain/testing.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

class _Box3dTestHandle implements MarbleTestHandle {
  new(this._simulation);

  final Box3dMarbleSimulation _simulation;

  @override
  void placeMarble(Vector3 position) => _simulation.placeMarble(position);

  @override
  void setMarbleVelocity(Vector3 velocity) =>
      _simulation.setMarbleVelocity(velocity);
}

void main() {
  setUpAll(Box3d.ensureInitialized);

  runMarbleSimulationContractTests(() {
    final simulation = Box3dMarbleSimulation();
    return MarbleSimulationHarness(
      simulation: simulation,
      handle: _Box3dTestHandle(simulation),
      maxSpeed: simulation.config.maxSpeed,
    );
  });
}
