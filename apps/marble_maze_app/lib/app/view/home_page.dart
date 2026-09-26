import 'package:marble_maze_app/app/routes/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// A temporary home screen with a single button that opens the bundled
/// sample level. Level select replaces this screen once it exists.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => const LevelPlayRoute(id: 'first_roll').go(context),
          child: const Text('Play First Roll'),
        ),
      ),
    );
  }
}
