import 'package:material_ui/material_ui.dart';

/// Full-screen page that hosts a 3D scene view.
class ScenePreviewPage extends StatelessWidget {
  const new({required this.sceneView, super.key});

  /// The 3D view to show.
  final Widget sceneView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: sceneView),
    );
  }
}
