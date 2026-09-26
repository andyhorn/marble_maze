import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The win panel shown once the marble reaches the exit: [time], [par] if
/// the level has one, and a button back to level select.
///
/// Best time, `isNewBest`, and Next/Retry are out of scope here (#8).
class LevelPlayWonOverlay extends StatelessWidget {
  /// Creates a level play won overlay.
  const new({
    required this.time,
    required this.par,
    required this.onBackToLevels,
    super.key,
  });

  /// The time elapsed from start to exit.
  final Duration time;

  /// The level's par time, shown only if not null.
  final Duration? par;

  /// Called when the player taps "Back to levels".
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final par = this.par;
    return Center(
      child: OverlayPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.levelPlayWonTimeLabel(formatDuration(time))),
            if (par != null)
              Text(l10n.levelPlayWonParLabel(formatDuration(par))),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: onBackToLevels,
              child: Text(l10n.backToLevels),
            ),
          ],
        ),
      ),
    );
  }
}
