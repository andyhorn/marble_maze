// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $levelSelectRoute,
  $settingsRoute,
  $bubbleLevelRoute,
  $levelPlayRoute,
];

RouteBase get $levelSelectRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $LevelSelectRoute._fromState,
);

mixin $LevelSelectRoute on GoRouteData {
  static LevelSelectRoute _fromState(GoRouterState state) =>
      const LevelSelectRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsRoute => GoRouteData.$route(
  path: '/settings',
  hasOverriddenOnExit: false,
  factory: $SettingsRoute._fromState,
);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $bubbleLevelRoute => GoRouteData.$route(
  path: '/bubble-level',
  hasOverriddenOnExit: false,
  factory: $BubbleLevelRoute._fromState,
);

mixin $BubbleLevelRoute on GoRouteData {
  static BubbleLevelRoute _fromState(GoRouterState state) =>
      const BubbleLevelRoute();

  @override
  String get location => GoRouteData.$location('/bubble-level');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $levelPlayRoute => GoRouteData.$route(
  path: '/level/:id',
  hasOverriddenOnExit: false,
  factory: $LevelPlayRoute._fromState,
);

mixin $LevelPlayRoute on GoRouteData {
  static LevelPlayRoute _fromState(GoRouterState state) =>
      LevelPlayRoute(id: state.pathParameters['id']!);

  LevelPlayRoute get _self => this as LevelPlayRoute;

  @override
  String get location =>
      GoRouteData.$location('/level/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
