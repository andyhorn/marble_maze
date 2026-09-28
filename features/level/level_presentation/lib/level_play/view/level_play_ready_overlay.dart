import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The "tap to start" panel shown while the level is ready and waiting for
/// the player. Tapping anywhere calls [onStart]; the back button calls
/// [onBackToLevels] instead.
class LevelPlayReadyOverlay extends StatelessWidget {
  /// Creates a level play ready overlay. [onStart] is called on tap and
  /// [onBackToLevels] when the back button is pressed.
  const new({required this.onStart, required this.onBackToLevels, super.key});

  /// Called when the player taps to start the level.
  final VoidCallback onStart;

  /// Called when the player chooses to return to level select.
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStart,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              onPressed: onStart,
              child: Text(l10n.levelPlayTapToStart),
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
