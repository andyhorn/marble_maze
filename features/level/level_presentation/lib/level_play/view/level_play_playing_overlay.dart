import 'package:level_presentation/level_play/cubit/level_play_cubit.dart';
import 'package:level_presentation/level_play/input/level_play_input_controller.dart';
import 'package:level_presentation/level_play/view/level_play_hud.dart';
import 'package:level_presentation/level_play/view/level_play_tilt_hint.dart';
import 'package:material_ui/material_ui.dart';

/// The overlay shown while the level is playing or falling: the HUD, plus
/// the "drag to tilt" hint while [controller] is showing it.
class LevelPlayPlayingOverlay extends StatelessWidget {
  /// Creates a level play playing overlay.
  const new({
    required this.cubit,
    required this.title,
    required this.controller,
    super.key,
  });

  /// The cubit the HUD reads the elapsed time from.
  final LevelPlayCubit cubit;

  /// The level's display title.
  final String title;

  /// The input controller whose hint visibility this overlay follows.
  final LevelPlayInputController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LevelPlayHud(cubit: cubit, title: title),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.showHint
              ? const LevelPlayTiltHint()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
