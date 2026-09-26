import 'package:flutter/material.dart';

class ScenePreviewPage extends StatelessWidget {
  const new({required this.sceneView, super.key});

  final Widget sceneView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: sceneView),
    );
  }
}
