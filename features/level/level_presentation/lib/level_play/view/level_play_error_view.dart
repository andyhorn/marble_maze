import 'package:material_ui/material_ui.dart';

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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This level could not be loaded.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBackToLevels,
              child: const Text('Back to levels'),
            ),
          ],
        ),
      ),
    );
  }
}
