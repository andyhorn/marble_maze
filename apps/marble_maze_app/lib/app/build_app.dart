import 'dart:developer';

import 'package:box3d/box3d.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:level_data/level_data.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:marble_maze_app/app/view/app.dart';
import 'package:marble_maze_app/app/view/unsupported_device_app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:progress_data_shared_preferences/progress_data_shared_preferences.dart';
import 'package:progress_domain/progress_domain.dart';
import 'package:settings_data_shared_preferences/settings_data_shared_preferences.dart';
import 'package:settings_domain/settings_domain.dart';
import 'package:tilt_data_sensors_plus/tilt_data_sensors_plus.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// Builds the app: a [LevelsRepository] reading bundled level assets, a
/// [SharedPreferencesProgressRepository] for saved best times, a
/// [SharedPreferencesSettingsRepository] for saved settings, a
/// [SensorsPlusTiltRepository] for tilt input, and the typed [GoRouter]
/// routes.
///
/// [isFlutterGpuAvailable] gates startup on Flutter GPU (and so Impeller)
/// being available, defaulting to the real probe; a test overrides it to
/// exercise the unsupported path without a real GPU. If it reports `false`,
/// or if [Box3d.ensureInitialized] (needed before a `Box3dMarbleSimulation`
/// can be constructed) fails, this returns an [UnsupportedDeviceApp]
/// instead of crashing deeper into the render or physics path.
Future<Widget> buildApp({
  Future<bool> Function() isFlutterGpuAvailable = isFlutterGpuAvailable,
}) async {
  if (!await isFlutterGpuAvailable()) {
    log('Flutter GPU is unavailable; showing the unsupported-device screen.');
    return const UnsupportedDeviceApp();
  }

  try {
    await Box3d.ensureInitialized();
  } on Exception catch (error, stackTrace) {
    log(
      'Box3d failed to initialize; showing the unsupported-device screen.',
      error: error,
      stackTrace: stackTrace,
    );
    return const UnsupportedDeviceApp();
  }

  final levelsRepository = LevelsRepository(
    dataSource: AssetLevelDataSource(loader: rootBundle.loadString),
  );
  final progressRepository = SharedPreferencesProgressRepository();
  final settingsRepository = SharedPreferencesSettingsRepository();
  final tiltRepository = SensorsPlusTiltRepository();
  final router = GoRouter(
    routes: $appRoutes,
    observers: [levelSelectRouteObserver],
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ILevelsRepository>.value(value: levelsRepository),
      RepositoryProvider<IProgressRepository>.value(value: progressRepository),
      RepositoryProvider<ISettingsRepository>.value(value: settingsRepository),
      RepositoryProvider<ITiltRepository>.value(value: tiltRepository),
    ],
    child: App(router: router),
  );
}
