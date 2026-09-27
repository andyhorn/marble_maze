import 'package:flutter_scene/scene.dart';

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
Future<bool> isFlutterGpuAvailable() async {
  await Scene.initializeStaticResources();
  return Scene.isReadyToRender;
}
