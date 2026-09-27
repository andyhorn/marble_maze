import 'package:flutter/scheduler.dart';
import 'package:level_presentation/level_play/cubit/level_play_cubit.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The playing/falling HUD: [title], an elapsed time read from [cubit]
/// (refreshed every frame by this widget's own [Ticker]), and a pause
/// button that calls [onPause].
class LevelPlayHud extends StatefulWidget {
  /// Creates a level play HUD for [title], timed by [cubit].
  const new({
    required this.cubit,
    required this.title,
    required this.onPause,
    super.key,
  });

  /// The cubit this HUD reads the elapsed time from every frame.
  final LevelPlayCubit cubit;

  /// The level's display title.
  final String title;

  /// Called when the player taps the pause button.
  final VoidCallback onPause;

  @override
  State<LevelPlayHud> createState() => _LevelPlayHudState();
}

class _LevelPlayHudState extends State<LevelPlayHud>
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
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: textStyle),
            Text(formatDuration(widget.cubit.elapsed), style: textStyle),
            IconButton(
              icon: const Icon(Icons.pause),
              tooltip: context.l10n.levelPlayPause,
              onPressed: widget.onPause,
            ),
          ],
        ),
      ),
    );
  }
}
