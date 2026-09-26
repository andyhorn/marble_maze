import 'package:material_ui/material_ui.dart';

/// The level play screen: a full-screen 3D [boardView].
///
/// [boardView] sits behind a seam so widget tests can swap in a
/// placeholder, since Flutter GPU does not render in widget tests.
class LevelPlayView extends StatelessWidget {
  /// Creates a level play view around [boardView].
  const new({required this.boardView, super.key});

  /// The 3D view of the board and marble.
  final Widget boardView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: boardView),
    );
  }
}
