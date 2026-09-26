import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The "tap to start" panel shown while the level is ready and waiting for
/// the player. Tapping anywhere calls [onStart].
class LevelPlayReadyOverlay extends StatelessWidget {
  /// Creates a level play ready overlay. [onStart] is called on tap.
  const new({required this.onStart, super.key});

  /// Called when the player taps to start the level.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStart,
      child: Center(
        child: OverlayPanel(child: Text(context.l10n.levelPlayTapToStart)),
      ),
    );
  }
}
