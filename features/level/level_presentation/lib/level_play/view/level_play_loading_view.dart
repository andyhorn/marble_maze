import 'package:material_ui/material_ui.dart';

/// Shown while the level play cubit loads a level.
class LevelPlayLoadingView extends StatelessWidget {
  /// Creates a level play loading view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
