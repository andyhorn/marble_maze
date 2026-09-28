import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/bubble_level/bubble_level.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// A small bubble level in the bottom-right corner of the screen, showing
/// the device's tilt while playing.
///
/// Draws nothing until the first accelerometer reading arrives, so a
/// touch-only device never shows a dead gauge. Ignores pointer events so it
/// never blocks a drag.
class LevelPlayBubbleLevel extends StatelessWidget {
  /// Creates a level play bubble level.
  const new({super.key});

  /// The gauge's width and height.
  static const double size = 88;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BubbleLevelCubit(tiltRepository: context.read<ITiltRepository>()),
      child: BlocBuilder<BubbleLevelCubit, BubbleLevelState>(
        builder: (context, state) {
          if (!state.hasReading) return const SizedBox.shrink();
          return IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox.square(
                    dimension: size,
                    child: BubbleLevelGauge(
                      xAngle: state.xAngle,
                      yAngle: state.yAngle,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
