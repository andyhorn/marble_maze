import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class CubeSceneView extends StatefulWidget {
  const new({super.key});

  @override
  State<CubeSceneView> createState() => _CubeSceneViewState();
}

class _CubeSceneViewState extends State<CubeSceneView> {
  final Scene _scene = Scene();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_buildScene());
  }

  Future<void> _buildScene() async {
    // Geometry and materials need the shader bundle, which is only available
    // once the engine's static resources are loaded.
    await Scene.initializeStaticResources();
    final cube = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(1, 1, 1)),
        PhysicallyBasedMaterial(),
      ),
    );
    _scene.add(cube);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.expand();
    return SceneView(
      _scene,
      camera: PerspectiveCamera(position: vm.Vector3(2, 2, -4)),
    );
  }
}
