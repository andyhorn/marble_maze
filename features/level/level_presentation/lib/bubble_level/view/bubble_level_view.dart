import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/bubble_level/cubit/bubble_level_cubit.dart';
import 'package:level_presentation/bubble_level/cubit/bubble_level_state.dart';
import 'package:level_presentation/bubble_level/view/bubble_level_gauge.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The bubble level screen: a spirit level driven by the accelerometer,
/// showing the device's tilt from flat as a bubble and in degrees.
class BubbleLevelView extends StatelessWidget {
  /// Creates a bubble level view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bubbleLevelTitle)),
      body: SafeArea(
        child: BlocBuilder<BubbleLevelCubit, BubbleLevelState>(
          builder: (context, state) {
            if (!state.hasReading) {
              return Center(child: Text(context.l10n.bubbleLevelWaiting));
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: BubbleLevelGauge(
                        xAngle: state.xAngle,
                        yAngle: state.yAngle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'X ${_degrees(state.xAngle)}   '
                      'Y ${_degrees(state.yAngle)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _degrees(double radians) =>
      '${(radians * 180 / math.pi).toStringAsFixed(1)}°';
}
