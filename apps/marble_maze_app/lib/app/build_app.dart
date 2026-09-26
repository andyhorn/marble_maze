import 'package:box3d/box3d.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/arena_level.dart';
import 'package:marble_maze_app/app/view/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_data_box3d/simulation_data_box3d.dart';

/// Builds the app around a fresh [Box3dMarbleSimulation] loaded with the
/// hard-coded [arenaLevel].
///
/// Awaits [Box3d.ensureInitialized] first: constructing a simulation
/// requires the physics backend to already be loaded.
Future<Widget> buildApp() async {
  await Box3d.ensureInitialized();
  final simulation = Box3dMarbleSimulation();
  return App(
    boardView: BoardSceneView(level: arenaLevel, simulation: simulation),
  );
}
