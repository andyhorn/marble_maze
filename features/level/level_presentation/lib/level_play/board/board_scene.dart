import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:flutter_scene/scene.dart';
import 'package:level_presentation/level_play/board/board_textures.dart';
import 'package:level_presentation/level_play/lighting/board_light.dart';
import 'package:simulation_domain/simulation_domain.dart' show kMarbleRadius;
import 'package:tilt_domain/tilt_domain.dart';

const _boardLight = BoardLight();

/// The bundled HDR environment map used for image-based lighting. See
/// `assets/hdr/ASSETS.md` for its source and licence.
const _environmentAsset =
    'packages/level_presentation/assets/hdr/studio_small_03_1k.hdr';

/// The directional light's intensity, raised above flutter_scene's default
/// (`3.0`) so lit surfaces read clearly brighter than [_environmentIntensity]
/// dimmed shadow, keeping the directional light (and so its shadows) the
/// dominant read rather than the ambient IBL term.
const double _directionalLightIntensity = 4.5;

/// Whether the directional shadow caches `shadowStatic` nodes across
/// frames: `false`, since the light's direction changes every frame as the
/// board tilts, and rebuilding and replaying a cache would cost more than
/// rendering casters directly.
const bool _shadowCacheStaticShadows = false;

/// The directional shadow's cascade count: `1`, since the light's direction
/// changes every frame (see [_shadowCacheStaticShadows]) and the scene's
/// small, fixed-height view has no need to spread resolution over several
/// cascades at different distances.
const int _shadowCascadeCount = 1;

/// The directional shadow map's resolution, raised above flutter_scene's
/// default (`1024`) so a wall's shadow edge stays crisp at typical phone
/// screen sizes instead of visibly blocky.
const int _shadowMapResolution = 2048;

/// The directional shadow's penumbra softness, lowered below flutter_scene's
/// default (`0.08`) for a crisper, more legible shadow edge on a small
/// screen.
const double _shadowSoftness = 0.05;

/// The image-based (HDR environment) lighting's intensity, dimmed well below
/// its default (`1.0`) so it fills in ambient light without competing with,
/// or washing out, the directional light's cast shadows.
const double _environmentIntensity = 0.35;

/// Screen-space ambient occlusion's strength: enabled, but at a modest
/// fraction of its calibrated default (`1.0`), for a soft contact shadow in
/// creases and corners on top of the directional light's own shadows.
const double _ambientOcclusionIntensity = 0.6;

/// How much of the screen-space occlusion also darkens the directional
/// light, not just the (already dimmed) ambient IBL term: `0` by default,
/// which would make ambient occlusion's contribution too faint to notice
/// once [_environmentIntensity] is this low.
const double _ambientOcclusionDirectLightAffect = 0.25;

/// The `Scene`, light, environment and marble that every board shares, built
/// once and reused across levels.
///
/// A new `Scene` allocates its render targets on its first frame, a stall of
/// about 125 ms on a phone. This one keeps them, so only the first level
/// pays it. Only one board can be shown at a time: [attach] evicts the one
/// on display.
class BoardScene {
  new _(this.textures) : scene = Scene() {
    marbleNode = Node(
      mesh: Mesh(
        SphereGeometry(radius: kMarbleRadius),
        PhysicallyBasedMaterial()
          ..baseColorTexture = textures.marble
          ..metallicFactor = 0
          ..roughnessFactor = 0.35,
      ),
    );
  }

  /// The textures the board and marble share.
  final BoardTextures textures;

  /// The shared scene.
  final Scene scene;

  /// The marble, positioned by whichever board is on display.
  late final Node marbleNode;

  Node? _boardRoot;
  VoidCallback? _onEvicted;

  static Future<BoardScene>? _pending;

  /// Builds the shared scene on first use and returns the same instance
  /// afterwards; concurrent callers share one in-flight build.
  ///
  /// A failed build is not cached, so a later call retries.
  static Future<BoardScene> load() {
    final pending = _pending ??= _create();
    unawaited(
      pending.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_pending, pending)) _pending = null;
        },
      ),
    );
    return pending;
  }

  /// Starts [load] without waiting for it, so the scene is ready by the time
  /// a level asks for it. A failure here is swallowed: the level that needs
  /// the scene calls [load] itself and surfaces any error.
  static void preload() =>
      unawaited(load().then<void>((_) {}, onError: (_) {}));

  static Future<BoardScene> _create() async {
    // Geometry and materials need the shader bundle, which is only
    // available once the engine's static resources are loaded.
    await Scene.initializeStaticResources();
    final board = BoardScene._(await BoardTextures.load());
    board.scene
      ..add(board.marbleNode)
      ..directionalLight = DirectionalLight(
        direction: _boardLight.directionFor(Tilt.flat),
        intensity: _directionalLightIntensity,
        castsShadow: true,
        cacheStaticShadows: _shadowCacheStaticShadows,
        shadowCascadeCount: _shadowCascadeCount,
        shadowMapResolution: _shadowMapResolution,
        shadowSoftness: _shadowSoftness,
      )
      // A patterned, non-metallic marble no longer needs a mirror highlight
      // bloomed out; disabled so it doesn't wash out the swirl texture.
      ..postProcess.bloom.enabled = false
      // Modest screen-space contact shadowing in wall/floor creases, on top
      // of the directional light's own cast shadows.
      ..ambientOcclusion.enabled = true
      ..ambientOcclusion.intensity = _ambientOcclusionIntensity
      ..ambientOcclusion.directLightAffect = _ambientOcclusionDirectLightAffect;
    await board.scene.loadEnvironment(
      _environmentAsset,
      // The camera always looks straight down and cover-fits the board to
      // the viewport, so the sky is never seen; disabling it is a cheap
      // saving.
      showSkybox: false,
      // Dimmed well below the directional light's contribution, so cast
      // shadows read clearly instead of being washed out by ambient IBL.
      intensity: _environmentIntensity,
    );
    return board;
  }

  /// Shows [root] as the board, in place of any board already on display.
  ///
  /// The previous board's root is removed and its `onEvicted` is called, so
  /// it stops driving the scene. [onEvicted] is called if a later [attach]
  /// takes the scene over.
  void attach(Node root, {required VoidCallback onEvicted}) {
    final previousRoot = _boardRoot;
    final previousOnEvicted = _onEvicted;
    if (previousRoot != null) scene.remove(previousRoot);
    scene.add(root);
    _boardRoot = root;
    _onEvicted = onEvicted;
    previousOnEvicted?.call();
  }

  /// Removes [root] from the scene if it is still the board on display; does
  /// nothing if another board has since taken over.
  void detach(Node root) {
    if (!identical(_boardRoot, root)) return;
    scene.remove(root);
    _boardRoot = null;
    _onEvicted = null;
  }
}
