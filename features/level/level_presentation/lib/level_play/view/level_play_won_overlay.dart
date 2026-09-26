import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The win panel shown once the marble reaches the exit: [time], [par] if
/// the level has one, [bestTime] with a "new best" badge when [isNewBest],
/// and Next / Retry / Levels buttons.
///
/// [onNext] is null on the last level, hiding the Next button.
class LevelPlayWonOverlay extends StatelessWidget {
  /// Creates a level play won overlay.
  const new({
    required this.time,
    required this.par,
    required this.bestTime,
    required this.isNewBest,
    required this.onNext,
    required this.onRetry,
    required this.onBackToLevels,
    super.key,
  });

  /// The time elapsed from start to exit.
  final Duration time;

  /// The level's par time, shown only if not null.
  final Duration? par;

  /// The best time saved for this level, including this run.
  final Duration bestTime;

  /// Whether this run set a new best time.
  final bool isNewBest;

  /// Called when the player taps "Next". Null on the last level, which
  /// hides the button.
  final VoidCallback? onNext;

  /// Called when the player taps "Retry".
  final VoidCallback onRetry;

  /// Called when the player taps "Levels".
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final par = this.par;
    final onNext = this.onNext;
    return Center(
      child: OverlayPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.levelPlayWonTimeLabel(formatDuration(time))),
            if (par != null)
              Text(l10n.levelPlayWonParLabel(formatDuration(par))),
            Text(l10n.levelPlayWonBestLabel(formatDuration(bestTime))),
            if (isNewBest) Text(l10n.levelPlayWonNewBestBadge),
            const SizedBox(height: 16),
            if (onNext != null)
              PrimaryButton(
                onPressed: onNext,
                child: Text(l10n.levelPlayWonNext),
              ),
            const SizedBox(height: 8),
            SecondaryButton(
              onPressed: onRetry,
              child: Text(l10n.levelPlayWonRetry),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              onPressed: onBackToLevels,
              child: Text(l10n.backToLevels),
            ),
          ],
        ),
      ),
    );
  }
}
