import 'package:material_ui/material_ui.dart';

/// The level play screen: a full-screen 3D [boardView], with an optional
/// [overlay] drawn over it (the "tap to start" panel, the HUD, or the win
/// panel).
///
/// [boardView] sits behind a seam so widget tests can swap in a
/// placeholder, since Flutter GPU does not render in widget tests.
class LevelPlayView extends StatelessWidget {
  /// Creates a level play view around [boardView], with an optional
  /// [overlay].
  const new({required this.boardView, this.overlay, super.key});

  /// The 3D view of the board and marble.
  final Widget boardView;

  /// Drawn over [boardView], if not null.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: boardView),
          ?overlay,
        ],
      ),
    );
  }
}
