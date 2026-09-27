import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The overlay shown while the level is paused: a title, Resume, and "Back
/// to levels" buttons.
///
/// A full-screen [ModalBarrier] sits behind the panel so touches meant for
/// the board underneath (drag-to-tilt) are absorbed rather than passed
/// through, while the panel's own buttons still receive theirs.
class LevelPlayPausedOverlay extends StatelessWidget {
  /// Creates a level play paused overlay.
  const new({required this.onResume, required this.onBackToLevels, super.key});

  /// Called when the player taps "Resume".
  final VoidCallback onResume;

  /// Called when the player taps "Back to levels".
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.transparent),
        Center(
          child: OverlayPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.levelPlayPausedTitle),
                const SizedBox(height: 16),
                PrimaryButton(
                  onPressed: onResume,
                  child: Text(l10n.levelPlayResume),
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  onPressed: onBackToLevels,
                  child: Text(l10n.backToLevels),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
