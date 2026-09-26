import 'package:box3d/box3d.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:marble_maze_app/app/view/app.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the app: a [LevelsRepository] reading bundled level assets, and
/// the typed [GoRouter] routes.
///
/// Awaits [Box3d.ensureInitialized] first: constructing a
/// `Box3dMarbleSimulation` requires the physics backend to already be
/// loaded.
Future<Widget> buildApp() async {
  await Box3d.ensureInitialized();

  final levelsRepository = LevelsRepository(
    dataSource: AssetLevelDataSource(loader: rootBundle.loadString),
  );
  final router = GoRouter(routes: $appRoutes);

  return RepositoryProvider<ILevelsRepository>.value(
    value: levelsRepository,
    child: App(router: router),
  );
}
