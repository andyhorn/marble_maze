import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// Shown when the level play cubit fails to load a level, for example an
/// unknown level id.
class LevelPlayErrorView extends StatelessWidget {
  /// Creates a level play error view. [onBackToLevels] is called when the
  /// player taps the back button.
  const new({required this.onBackToLevels, super.key});

  /// Called when the player taps the back button.
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.levelPlayErrorMessage),
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
