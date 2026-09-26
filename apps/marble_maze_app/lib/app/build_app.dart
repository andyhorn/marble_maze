import 'package:box3d/box3d.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:marble_maze_app/app/view/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tilt_data_sensors_plus/tilt_data_sensors_plus.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// Builds the app: a [LevelsRepository] reading bundled level assets, a
/// [SensorsPlusTiltRepository] for tilt input, and the typed [GoRouter]
/// routes.
///
/// Awaits [Box3d.ensureInitialized] first: constructing a
/// `Box3dMarbleSimulation` requires the physics backend to already be
/// loaded.
Future<Widget> buildApp() async {
  await Box3d.ensureInitialized();

  final levelsRepository = LevelsRepository(
    dataSource: AssetLevelDataSource(loader: rootBundle.loadString),
  );
  final tiltRepository = SensorsPlusTiltRepository();
  final router = GoRouter(routes: $appRoutes);

  return RepositoryProvider<ILevelsRepository>.value(
    value: levelsRepository,
    child: RepositoryProvider<ITiltRepository>.value(
      value: tiltRepository,
      child: App(router: router),
    ),
  );
}
