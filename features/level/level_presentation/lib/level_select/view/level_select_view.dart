import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/level_select/cubit/level_select_cubit.dart';
import 'package:level_presentation/level_select/cubit/level_select_state.dart';
import 'package:level_presentation/level_select/level_select_route_observer.dart';
import 'package:level_presentation/level_select/view/level_list_item.dart';
import 'package:level_presentation/level_select/view/level_select_error_view.dart';
import 'package:level_presentation/level_select/view/level_select_loading_view.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The level select screen: every manifest level with its best time and par
/// status, or a loading/error view while the [LevelSelectCubit] fetches
/// them.
///
/// Reloads whenever the player returns to this screen (for example after
/// finishing a level), so a newly saved best time appears without a
/// restart.
class LevelSelectView extends StatefulWidget {
  /// Creates a level select view. [onLevelSelected] is called with a
  /// level's id when its row is tapped, and [onOpenSettings] when the app
  /// bar's settings button is tapped.
  const new({
    required this.onLevelSelected,
    required this.onOpenSettings,
    super.key,
  });

  /// Called when the player taps a level's row.
  final ValueChanged<String> onLevelSelected;

  /// Called when the player taps the settings button.
  final VoidCallback onOpenSettings;

  @override
  State<LevelSelectView> createState() => _LevelSelectViewState();
}

class _LevelSelectViewState extends State<LevelSelectView> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      levelSelectRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    levelSelectRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    unawaited(context.read<LevelSelectCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LevelSelectCubit, LevelSelectState>(
      builder: (context, state) => switch (state) {
        LevelSelectLoading() => const LevelSelectLoadingView(),
        LevelSelectLoaded(:final entries) => Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.levelSelectTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: context.l10n.settingsTooltip,
                onPressed: widget.onOpenSettings,
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return LevelListItem(
                entry: entry,
                onTap: () => widget.onLevelSelected(entry.id),
              );
            },
          ),
        ),
        LevelSelectError() => const LevelSelectErrorView(),
      },
    );
  }
}
