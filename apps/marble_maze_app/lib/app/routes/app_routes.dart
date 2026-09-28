import 'package:go_router/go_router.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_data_box3d/simulation_data_box3d.dart';

part 'app_routes.g.dart';

/// The level select route: every bundled level, with its best time and par
/// status.
@TypedGoRoute<LevelSelectRoute>(path: '/')
class LevelSelectRoute extends GoRouteData with $LevelSelectRoute {
  /// Creates the level select route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => LevelSelectModule(
    onLevelSelected: (id) => LevelPlayRoute(id: id).push<void>(context),
    onOpenSettings: () => const SettingsRoute().push<void>(context),
  );
}

/// The settings route: tilt calibration, and a link to the bubble level.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates the settings route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => SettingsModule(
    onOpenBubbleLevel: () => const BubbleLevelRoute().push<void>(context),
  );
}

/// The bubble level route: a spirit level driven by the accelerometer.
@TypedGoRoute<BubbleLevelRoute>(path: '/bubble-level')
class BubbleLevelRoute extends GoRouteData with $BubbleLevelRoute {
  /// Creates the bubble level route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BubbleLevelModule();
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
    // Keyed by id: Next replaces this route in place with a new id, and
    // without a key the element (and its cubit and simulation) would be
    // reused for the old level instead of being rebuilt for the new one.
    key: ValueKey(id),
    levelId: id,
    simulationFactory: Box3dMarbleSimulation.new,
    onExitToLevels: () => const LevelSelectRoute().go(context),
    onNextLevel: (nextId) => LevelPlayRoute(id: nextId).replace(context),
  );
}
