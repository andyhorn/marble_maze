import 'package:flutter/scheduler.dart';
import 'package:level_presentation/bubble_level/bubble_level.dart';
import 'package:level_presentation/level_play/input/level_play_input_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// A small bubble level in the bottom-right corner of the screen, showing
/// the board's tilt as [controller] applies it (calibration, dead zone and
/// clamp included), whether it comes from the accelerometer or from touch.
///
/// The bubble floats to the board's high side, opposite the way the marble
/// rolls, and reaches the vial's edge at [Tilt.maxTilt]. Ignores pointer
/// events so it never blocks a drag.
class LevelPlayBubbleLevel extends StatefulWidget {
  /// Creates a level play bubble level showing [controller]'s tilt.
  const new({required this.controller, super.key});

  /// The input controller whose [LevelPlayInputController.lastTilt] this
  /// bubble shows.
  final LevelPlayInputController controller;

  /// The gauge's width and height.
  static const double size = 88;

  @override
  State<LevelPlayBubbleLevel> createState() => _LevelPlayBubbleLevelState();
}

class _LevelPlayBubbleLevelState extends State<LevelPlayBubbleLevel>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tilt = widget.controller.lastTilt;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox.square(
              dimension: LevelPlayBubbleLevel.size,
              // Tilt's axes describe where the marble rolls; the bubble
              // goes the other way, to the board's high side.
              child: BubbleLevelGauge(
                xAngle: -tilt.x,
                yAngle: -tilt.y,
                fullScaleAngle: Tilt.maxTilt,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
