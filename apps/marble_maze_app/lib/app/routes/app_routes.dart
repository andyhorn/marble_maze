import 'package:go_router/go_router.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/view/home_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_data_box3d/simulation_data_box3d.dart';

part 'app_routes.g.dart';

/// The temporary home route. Level select replaces this once it exists.
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// The level play route: loads and plays the level with [id].
@TypedGoRoute<LevelPlayRoute>(path: '/level/:id')
class LevelPlayRoute extends GoRouteData with $LevelPlayRoute {
  /// Creates a level play route for [id].
  const new({required this.id});

  /// The id of the level to play.
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) => LevelPlayModule(
    levelId: id,
    simulationFactory: Box3dMarbleSimulation.new,
    onExitToLevels: () => const HomeRoute().go(context),
  );
}
