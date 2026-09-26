import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The one-time "drag to tilt" hint shown while the level uses touch-only
/// input, near the bottom of the screen so it does not sit over the HUD.
///
/// Ignores pointer events so it never blocks the drag it's explaining.
class LevelPlayTiltHint extends StatelessWidget {
  /// Creates a level play tilt hint.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: OverlayPanel(
              child: Text(context.l10n.levelPlayDragToTiltHint),
            ),
          ),
        ),
      ),
    );
  }
}
