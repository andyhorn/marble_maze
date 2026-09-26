import 'package:material_ui/material_ui.dart';

/// Notifies the level select view when the player returns to it, so it can
/// reload the list to pick up a best time saved while playing.
///
/// The app registers this in its navigator's `observers`.
final levelSelectRouteObserver = RouteObserver<PageRoute<dynamic>>();
