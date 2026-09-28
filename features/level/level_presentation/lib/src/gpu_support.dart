import 'package:flutter_scene/scene.dart';
import 'package:level_presentation/level_play/board/board_scene.dart';

/// Probes whether Flutter GPU (and so Impeller) is available on this
/// device, without ever throwing.
///
/// `Scene.initializeStaticResources` is the same call `BoardSceneView`
/// awaits before its first frame: it never lets a backend failure (Impeller
/// disabled, the Flutter GPU manifest flag missing, or any other error
/// while loading the shared shader and material resources) escape as a
/// thrown exception, only leaving [Scene.isReadyToRender] false. That makes
/// it a safe, front-loaded readiness probe for a startup check, so a
/// caller can show an unsupported-device screen instead of crashing deeper
/// into the render path.
///
/// When the GPU is available this also starts loading the board scene
/// in the background, so entering a level doesn't wait on building it.
Future<bool> isFlutterGpuAvailable() async {
  await Scene.initializeStaticResources();
  final isAvailable = Scene.isReadyToRender;
  if (isAvailable) BoardScene.preload();
  return isAvailable;
}
