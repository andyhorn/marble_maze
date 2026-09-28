import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_select/cubit/level_select_cubit.dart';
import 'package:level_presentation/level_select/view/level_select_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:progress_domain/progress_domain.dart';

/// The level select screen's module: wires a [LevelSelectCubit] to the
/// [ILevelsRepository] and [IProgressRepository] from context.
class LevelSelectModule extends StatelessWidget {
  /// Creates a level select module.
  ///
  /// [onLevelSelected] is called with a level's id when its row is tapped,
  /// and [onOpenBubbleLevel] when the bubble level button is tapped.
  const new({
    required this.onLevelSelected,
    required this.onOpenBubbleLevel,
    super.key,
  });

  /// Called when the player taps a level's row.
  final ValueChanged<String> onLevelSelected;

  /// Called when the player taps the bubble level button.
  final VoidCallback onOpenBubbleLevel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = LevelSelectCubit(
          levelsRepository: context.read<ILevelsRepository>(),
          progressRepository: context.read<IProgressRepository>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: LevelSelectView(
        onLevelSelected: onLevelSelected,
        onOpenBubbleLevel: onOpenBubbleLevel,
      ),
    );
  }
}
