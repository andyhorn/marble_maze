import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_scene/scene.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/animation/marble_exit_animation.dart';
import 'package:level_presentation/level_play/animation/marble_sink_animation.dart';
import 'package:level_presentation/level_play/camera/board_camera.dart';
import 'package:level_presentation/level_play/haptics/haptics_decider.dart';
import 'package:level_presentation/level_play/input/level_play_input_controller.dart';
import 'package:level_presentation/level_play/lighting/board_light.dart';
import 'package:level_presentation/level_play/view/frame_clock.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The sink animation played when the marble falls into a hole or leaves
/// the board.
const _sinkAnimation = MarbleSinkAnimation();

/// The settle animation played when the marble reaches the exit.
const _exitAnimation = MarbleExitAnimation();

/// The camera's fitting, follow, and smoothing maths.
const _boardCamera = BoardCamera();

/// Tuning for the wall-hit and hole-fall haptic taps.
const _hapticsDecider = HapticsDecider();

/// The bundled HDR environment map used for image-based lighting. See
/// `assets/hdr/ASSETS.md` for its source and licence.
const _environmentAsset =
    'packages/level_presentation/assets/hdr/studio_small_03_1k.hdr';

/// The wood base-colour texture used for the floor and walls. See
/// `assets/textures/ASSETS.md` for its source and licence.
const _woodTextureAsset =
    'packages/level_presentation/assets/textures/'
    'fine_grained_wood_col_1k.jpg';

/// The generated marble base-colour swirl texture. See
/// `assets/textures/ASSETS.md` for how it's built.
const _marbleTextureAsset =
    'packages/level_presentation/assets/textures/marble_swirl.png';

/// How many world units of wood texture map to one UV tile. Chosen so the
/// grain doesn't stretch across the whole board, and, being a non-integer
/// fraction of a 1-unit cell, doesn't visibly repeat in lockstep with cell
/// boundaries either.
const double _woodUvUnitsPerTile = 1.6;

/// How deep, in world units, a hole's or the exit's cup is recessed below
/// the floor. `MarbleSinkAnimation` and `MarbleExitAnimation`'s default
/// depths match this, so the marble comes to rest exactly at the bottom.
const double _cupDepth = 0.5;

/// The directional light's travel direction maths: a world light that stays
/// fixed in place while the board tilts beneath it, so shadows shift with
/// tilt rather than staying put.
const _boardLight = BoardLight();

/// How many camera heights out the directional shadow's cascade reaches:
/// the whole scene is roughly one camera height away from the camera, so
/// this comfortably covers it without wasting resolution the way
/// flutter_scene's much larger default (`150`, spread over 4 cascades)
/// would with only [_shadowCascadeCount].
const double _shadowMaxDistanceFactor = 1.3;

/// The directional shadow's cascade count: `1`, since the light's direction
/// changes every frame (see [_shadowCacheStaticShadows]) and the scene's
/// small, fixed-height view has no need to spread resolution over several
/// cascades at different distances.
const int _shadowCascadeCount = 1;

/// Whether the directional shadow caches `shadowStatic` nodes across
/// frames: `false`, since the light's direction changes every frame as the
/// board tilts, and rebuilding and replaying a cache would cost more than
/// rendering casters directly.
const bool _shadowCacheStaticShadows = false;

/// The directional light's intensity, raised above flutter_scene's default
/// (`3.0`) so lit surfaces read clearly brighter than [_environmentIntensity]
/// dimmed shadow, keeping the directional light (and so its shadows) the
/// dominant read rather than the ambient IBL term.
const double _directionalLightIntensity = 4.5;

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

/// A harmless fallback background colour, never actually seen: the camera
/// always cover-fits the board to the viewport, so this never shows through.
/// A dark warm brown, matching the wood floor and walls, in case it ever
/// does.
const Color _boardBackgroundColor = Color(0xFF2B1D12);

/// Renders the board and marble with flutter_scene, and drives the frame
/// loop: reads the current tilt from [controller], steps [simulation], and
/// updates the scene from it.
///
/// The board is fixed to the screen, always: it never rotates, in either
/// accelerometer or touch mode. Instead, the camera looks straight down at
/// it and the directional light's travel direction shifts with the current
/// tilt (see [BoardLight]), so shadows read as though a world light stays
/// put while the board tilts beneath it. Gravity, not board rotation,
/// drives the physics inside [simulation] either way.
///
/// On a [FellInHole] or [LeftBoard] simulation event, this plays a sink
/// animation on the marble, then calls `simulation.respawn()`. [onMarbleFell]
/// and [onMarbleRespawned] notify the caller of those two moments so it can
/// drive its own state (for example a bloc cubit) without this view knowing
/// about it. A [ReachedExit] event calls [onReachedExit].
class BoardSceneView extends StatefulWidget {
  /// Creates a board scene view for [level], stepping [simulation] each
  /// frame while [isSimulationActive] is true.
  const new({
    required this.level,
    required this.simulation,
    required this.isSimulationActive,
    required this.controller,
    required this.onMarbleFell,
    required this.onMarbleRespawned,
    required this.onReachedExit,
    super.key,
  });

  /// The level to render and load into [simulation].
  final Level level;

  /// The input controller this view reads the tilt from and forwards touch
  /// drags to.
  final LevelPlayInputController controller;

  /// The marble simulation this view steps every frame.
  final IMarbleSimulation simulation;

  /// Whether [simulation] advances each frame. False while the marble sits
  /// still at the start (before the tap to start, and once it has won), and
  /// while paused, which also freezes the sink animation.
  final bool isSimulationActive;

  /// Called when the marble falls into a hole or leaves the board, before
  /// the sink animation starts.
  final VoidCallback onMarbleFell;

  /// Called once the sink animation completes and `simulation.respawn()`
  /// has been called.
  final VoidCallback onMarbleRespawned;

  /// Called when the marble reaches the level's exit.
  final VoidCallback onReachedExit;

  @override
  State<BoardSceneView> createState() => _BoardSceneViewState();
}

class _BoardSceneViewState extends State<BoardSceneView>
    with SingleTickerProviderStateMixin {
  final Scene _scene = Scene();
  final Node _boardRoot = Node();
  late final Node _marbleNode;
  late final PerspectiveCamera _camera;
  Ticker? _ticker;
  StreamSubscription<SimulationEvent>? _eventsSubscription;
  final FrameClock _frameClock = FrameClock();
  Duration? _fallStartElapsed;
  vm.Vector3? _fallStartPosition;
  vm.Vector3? _fallTargetCupCenter;
  Duration? _exitStartElapsed;
  vm.Vector3? _exitStartPosition;
  Duration? _lastWallHitImpactElapsed;
  // Null until the first tick, which snaps it straight to that frame's
  // tilt rather than easing in from flat.
  Tilt? _lightTilt;
  // Null until the first `_updateCamera` call, which snaps it straight to
  // that frame's target instead of smoothing in from `(0, 0)`: smoothing in
  // would otherwise visibly glide the camera into place right as the board
  // first appears.
  vm.Vector2? _cameraFocus;
  double _viewportAspectRatio = 16 / 9;
  bool _ready = false;

  // An alias so the fall-start timestamp below reads (and freezes while
  // paused) from the clock's active-only elapsed time, rather than
  // wall-clock ticker time.
  Duration get _lastElapsed => _frameClock.activeElapsed;

  bool get _isFalling => _fallStartElapsed != null;
  bool get _isExiting => _exitStartElapsed != null;

  @override
  void initState() {
    super.initState();
    widget.simulation.load(widget.level);
    _eventsSubscription = widget.simulation.events.listen(_onSimulationEvent);
    unawaited(_buildScene());
  }

  void _onSimulationEvent(SimulationEvent event) {
    _handleHaptics(event);
    if (_isFalling) return;
    switch (event) {
      case FellInHole(:final hole):
        _fallStartElapsed = _lastElapsed;
        _fallStartPosition = widget.simulation.marble.position.clone();
        _fallTargetCupCenter = gridPointCenter(
          hole,
          width: widget.level.width,
          height: widget.level.height,
        );
        widget.onMarbleFell();
      case LeftBoard():
        // No cup to roll toward: sinks straight down where it left the
        // board.
        _fallStartElapsed = _lastElapsed;
        _fallStartPosition = widget.simulation.marble.position.clone();
        _fallTargetCupCenter = null;
        widget.onMarbleFell();
      case ReachedExit():
        // The exit animation plays in the Won state, while the simulation
        // (and so the active-only clock) is stopped.
        _exitStartElapsed = _frameClock.totalElapsed;
        _exitStartPosition = widget.simulation.marble.position.clone();
        widget.onReachedExit();
      case HitWall():
        break;
    }
  }

  void _handleHaptics(SimulationEvent event) {
    final impact = _hapticsDecider.decide(
      event,
      _lastElapsed,
      lastWallHitImpactElapsed: _lastWallHitImpactElapsed,
    );
    switch (impact) {
      case HapticImpact.none:
        return;
      case HapticImpact.medium:
        _lastWallHitImpactElapsed = _lastElapsed;
        unawaited(HapticFeedback.mediumImpact());
      case HapticImpact.heavy:
        unawaited(HapticFeedback.heavyImpact());
    }
  }

  Future<void> _buildScene() async {
    // Geometry and materials need the shader bundle, which is only
    // available once the engine's static resources are loaded.
    await Scene.initializeStaticResources();

    final woodTexture = await Texture2D.fromAsset(_woodTextureAsset);
    final marbleTexture = await Texture2D.fromAsset(_marbleTextureAsset);

    _buildBoard(woodTexture);
    _marbleNode = Node(
      mesh: Mesh(
        SphereGeometry(radius: kMarbleRadius),
        PhysicallyBasedMaterial()
          ..baseColorTexture = marbleTexture
          ..metallicFactor = 0
          ..roughnessFactor = 0.35,
      ),
    );
    _boardRoot.add(_marbleNode);
    _camera = PerspectiveCamera(
      fovRadiansY: _boardCamera.fovRadiansY,
      position: vm.Vector3(0, 8, 0),
      target: vm.Vector3(0, 0, 0),
      // The default (0, 1, 0) is degenerate for a camera looking straight
      // down; this camera never looks anywhere else, so this never changes.
      up: vm.Vector3(0, 0, 1),
    );
    _scene
      ..add(_boardRoot)
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
    unawaited(
      _scene.loadEnvironment(
        _environmentAsset,
        // The camera always looks straight down and cover-fits the board to
        // the viewport, so the sky is never seen; disabling it is a cheap
        // saving.
        showSkybox: false,
        // Dimmed well below the directional light's contribution, so cast
        // shadows read clearly instead of being washed out by ambient IBL.
        intensity: _environmentIntensity,
      ),
    );

    if (!mounted) return;
    setState(() => _ready = true);
    _ticker = createTicker(_onTick)..start();
  }

  static const Color _cupColor = Color(0xFF141414);
  static const Color _exitCupColor = Colors.amber;

  /// A wall side's tint, multiplied over the shared wood texture: noticeably
  /// darker than the floor so walls read as distinct volumes rather than
  /// blending into it.
  static const double _wallSideTint = 0.55;

  /// A wall top's tint: lighter than [_wallSideTint] but still darker than
  /// the floor, so each wall shows a visible top edge against its own sides.
  static const double _wallTopTint = 0.72;

  /// `doubleSided` since floor tiles, opening rings, and wall faces are
  /// hand-built flat quads (see [_quadGeometry]); getting every face's
  /// winding order exactly right for backface culling is unnecessary risk
  /// for geometry this thin. [tint] multiplies the shared wood texture,
  /// darkening it uniformly without shifting its hue.
  static PhysicallyBasedMaterial _woodMaterial(
    Texture2D texture, {
    double tint = 1,
  }) => PhysicallyBasedMaterial()
    ..baseColorTexture = texture
    ..baseColorFactor = vm.Vector4(tint, tint, tint, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 0.75
    ..doubleSided = true;

  void _buildBoard(Texture2D woodTexture) {
    final level = widget.level;
    final wood = _woodMaterial(woodTexture);
    final wallSideWood = _woodMaterial(woodTexture, tint: _wallSideTint);
    final wallTopWood = _woodMaterial(woodTexture, tint: _wallTopTint);
    final openings = {...level.holes, level.exit};

    for (var row = 0; row < level.height; row++) {
      for (var column = 0; column < level.width; column++) {
        final point = GridPoint(column: column, row: row);
        final center = gridPointCenter(
          point,
          width: level.width,
          height: level.height,
        );
        if (openings.contains(point)) {
          _boardRoot.add(
            _floorOpeningRing(
              center: center,
              holeRadius: point == level.exit ? kExitRadius : kHoleRadius,
              material: wood,
            ),
          );
        } else {
          _boardRoot.add(_floorTile(center: center, material: wood));
        }
      }
    }

    for (final wall in level.walls) {
      final placement = wallRunPlacement(
        wall,
        width: level.width,
        height: level.height,
      );
      _boardRoot.add(
        _worldUvBoxNode(
          center: vm.Vector3(
            placement.center.x,
            kWallHeight / 2,
            placement.center.z,
          ),
          halfExtents: vm.Vector3(placement.halfLength, kWallHeight / 2, 0.5),
          topMaterial: wallTopWood,
          sideMaterial: wallSideWood,
        ),
      );
    }

    for (final hole in level.holes) {
      _boardRoot.add(
        _buildCup(hole, radius: kHoleRadius, level: level, color: _cupColor),
      );
    }
    _boardRoot.add(
      _buildCup(
        level.exit,
        radius: kExitRadius,
        level: level,
        color: _exitCupColor,
      ),
    );
  }

  static vm.Vector4 _colorToVector4(Color color) =>
      vm.Vector4(color.r, color.g, color.b, color.a);

  /// A flat, world-UV-mapped quad for one non-opening floor cell.
  Node _floorTile({
    required vm.Vector3 center,
    required PhysicallyBasedMaterial material,
  }) => Node(mesh: Mesh(_worldUvQuad(center: center), material));

  /// A flat quad covering a cell except for a round opening of [holeRadius]
  /// at its center, so the hole or exit's cup below shows through a real
  /// gap in the floor rather than the marble rolling over painted-on solid
  /// ground.
  Node _floorOpeningRing({
    required vm.Vector3 center,
    required double holeRadius,
    required PhysicallyBasedMaterial material,
  }) => Node(
    mesh: Mesh(
      _worldUvAnnulus(center: center, innerRadius: holeRadius),
      material,
    ),
  );

  /// A cup recessed [_cupDepth] below the floor: an open-topped cylinder (a
  /// side wall plus a bottom cap) so the marble visibly drops into it
  /// through the matching opening in the floor. `doubleSided` since the
  /// wall's inside face, the one the camera actually sees, would otherwise
  /// be back-face culled.
  Node _buildCup(
    GridPoint point, {
    required double radius,
    required Level level,
    required Color color,
  }) {
    final center = gridPointCenter(
      point,
      width: level.width,
      height: level.height,
    );
    return Node(
      mesh: Mesh(
        CylinderGeometry(
          bottomRadius: radius,
          topRadius: radius,
          height: _cupDepth,
          topCap: false,
        ),
        PhysicallyBasedMaterial()
          ..baseColorFactor = _colorToVector4(color)
          ..metallicFactor = 0
          ..roughnessFactor = 0.85
          ..doubleSided = true,
      ),
    )..position = vm.Vector3(center.x, -_cupDepth / 2, center.z);
  }

  void _onTick(Duration elapsed) {
    // Clamped so a stalled frame (for example while the app was
    // backgrounded, or while paused) does not dump a burst of physics or
    // animation on the next active frame; frozen while inactive so the
    // sink animation freezes and resumes from where it left off.
    final delta = _frameClock.tick(
      elapsed,
      isActive: widget.isSimulationActive,
    );

    widget.controller.update(delta);
    final tilt = widget.controller.tilt;

    // Not stepped while [BoardSceneView.isSimulationActive] is false
    // (Ready, Won, and Paused): the marble sits still at rest rather than
    // settling under gravity, and physics stays frozen while paused.
    if (widget.isSimulationActive) {
      widget.simulation.step(tilt, delta);
    }

    if (_isExiting && widget.simulation.marble.isActive) {
      // Retry respawns the simulation's marble, which ends the exit
      // animation that would otherwise keep drawing it in the cup.
      _exitStartElapsed = null;
      _exitStartPosition = null;
    }

    if (_isExiting) {
      _updateExitingMarble(_frameClock.totalElapsed);
    } else if (_isFalling) {
      _updateFallingMarble(_frameClock.activeElapsed);
    } else {
      final marble = widget.simulation.marble;
      _marbleNode
        ..position = marble.position
        ..rotation = marble.rotation
        ..scale = vm.Vector3.all(1);
    }

    // Read after the marble node update above, so the camera follows the
    // node's actual on-screen position (including during the fall and exit
    // animations) rather than the simulation's, which the animations
    // temporarily diverge from.
    final cameraHeight = _updateCamera(delta);

    final previousLightTilt = _lightTilt;
    final lightTilt = previousLightTilt == null
        ? tilt
        : _boardLight.smoothTowards(previousLightTilt, tilt, delta);
    _lightTilt = lightTilt;

    _scene.directionalLight!
      ..direction = _boardLight.directionFor(lightTilt)
      ..shadowMaxDistance = cameraHeight * _shadowMaxDistanceFactor;
  }

  void _updateExitingMarble(Duration elapsed) {
    final exitStart = _exitStartElapsed;
    final startPosition = _exitStartPosition;
    if (exitStart == null || startPosition == null) return;
    final sinceExit = elapsed - exitStart;

    final level = widget.level;
    final cupCenter = gridPointCenter(
      level.exit,
      width: level.width,
      height: level.height,
    );
    final progress = _exitAnimation.progressAt(sinceExit);
    final settled = vm.Vector3(
      startPosition.x + (cupCenter.x - startPosition.x) * progress,
      startPosition.y - _exitAnimation.sinkOffsetAt(sinceExit),
      startPosition.z + (cupCenter.z - startPosition.z) * progress,
    );
    _marbleNode.position = settled;
  }

  /// Advances the camera's X/Z focus toward the marble node's current
  /// position, smoothing frame-rate independently per axis, and updates
  /// [_camera] from it. Returns the camera's height above the floor, so the
  /// caller can size the directional shadow's cascade to it.
  double _updateCamera(Duration delta) {
    final level = widget.level;
    final boardWidth = level.width.toDouble();
    final boardHeight = level.height.toDouble();
    final marblePosition = _marbleNode.position;
    final target = _boardCamera.focusFor(
      marbleX: marblePosition.x,
      marbleZ: marblePosition.z,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      viewportAspectRatio: _viewportAspectRatio,
    );
    final currentFocus = _cameraFocus;
    final focus = currentFocus == null
        ? target
        : vm.Vector2(
            _boardCamera.smoothTowards(currentFocus.x, target.x, delta),
            _boardCamera.smoothTowards(currentFocus.y, target.y, delta),
          );
    _cameraFocus = focus;

    final pose = _boardCamera.poseFor(
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      viewportAspectRatio: _viewportAspectRatio,
      focus: focus,
    );
    _camera
      ..position = pose.position
      ..target = pose.target
      ..up = pose.up;
    return pose.position.y;
  }

  void _updateFallingMarble(Duration elapsed) {
    final fallStart = _fallStartElapsed;
    final startPosition = _fallStartPosition;
    if (fallStart == null || startPosition == null) return;
    final sinceFall = elapsed - fallStart;

    if (_sinkAnimation.isCompleteAt(sinceFall)) {
      widget.simulation.respawn();
      _fallStartElapsed = null;
      _fallStartPosition = null;
      _fallTargetCupCenter = null;
      widget.onMarbleRespawned();
      final respawned = widget.simulation.marble;
      _marbleNode
        ..position = respawned.position
        ..rotation = respawned.rotation
        ..scale = vm.Vector3.all(1);
      return;
    }

    // Rolls toward the hole's cup center in X/Z (or stays put for a
    // LeftBoard fall, which has no cup) while dropping to the cup's bottom.
    final target = _fallTargetCupCenter;
    final progress = _sinkAnimation.progressAt(sinceFall);
    final x = target == null
        ? startPosition.x
        : startPosition.x + (target.x - startPosition.x) * progress;
    final z = target == null
        ? startPosition.z
        : startPosition.z + (target.z - startPosition.z) * progress;
    final marble = widget.simulation.marble;
    _marbleNode
      ..position = vm.Vector3(
        x,
        startPosition.y - _sinkAnimation.sinkOffsetAt(sinceFall),
        z,
      )
      ..rotation = marble.rotation
      ..scale = vm.Vector3.all(_sinkAnimation.scaleAt(sinceFall));
  }

  void _onPanStart(DragStartDetails details) {
    final local = details.localPosition;
    widget.controller.dragStart(local.dx, local.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;
    widget.controller.dragUpdate(local.dx, local.dy);
  }

  void _onPanEnd(DragEndDetails details) => widget.controller.dragEnd();

  void _onPanCancel() => widget.controller.dragEnd();

  @override
  void dispose() {
    unawaited(_eventsSubscription?.cancel());
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight > 0) {
          final aspectRatio = constraints.maxWidth / constraints.maxHeight;
          if (aspectRatio != _viewportAspectRatio) {
            _viewportAspectRatio = aspectRatio;
            // The ticker's next frame runs before this build's measured
            // aspect ratio would otherwise reach it (transient callbacks
            // fire before build/layout), so a first-tick or post-rotation
            // snap-to-target would still land on a stale aspect ratio
            // without also resetting this: cleared so `_updateCamera` snaps
            // fresh instead of gliding from a focus computed for the old
            // one.
            _cameraFocus = null;
          }
        }
        return GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          // A harmless fallback that's never actually seen: the camera
          // always cover-fits the board to the viewport in both axes, so
          // `SceneView` fills this box completely every frame.
          child: ColoredBox(
            color: _boardBackgroundColor,
            child: SceneView(_scene, camera: _camera),
          ),
        );
      },
    );
  }
}

/// Builds one flat 1x1 world-UV floor quad centered at [center], facing
/// `+Y`. See [_quadGeometry].
MeshGeometry _worldUvQuad({required vm.Vector3 center, double halfSize = 0.5}) {
  return _quadGeometry(
    p00: vm.Vector3(center.x - halfSize, center.y, center.z - halfSize),
    u: vm.Vector3(halfSize * 2, 0, 0),
    v: vm.Vector3(0, 0, halfSize * 2),
    normal: vm.Vector3(0, 1, 0),
    uvOf: (p) => vm.Vector2(p.x, p.z) / _woodUvUnitsPerTile,
  );
}

/// Builds a flat quad in the [p00], [p00]+[u], [p00]+[v], [p00]+[u]+[v]
/// plane, with per-vertex UVs from [uvOf] and a single flat [normal].
///
/// Winds its two triangles the same way `flutter_scene`'s own
/// `buildPlaneArrays` does for a `+Y`-facing quad spanned by `u` (its local
/// X) and `v` (its local Z): `(p00, p00+v, p00+u)` then
/// `(p00+u, p00+v, p00+u+v)`. Callers of this private helper are expected to
/// pick `u` and `v` so that `cross(v, u)` equals the intended outward
/// [normal]; getting that wrong only affects backface culling, which every
/// caller here sidesteps by rendering with a `doubleSided` material.
MeshGeometry _quadGeometry({
  required vm.Vector3 p00,
  required vm.Vector3 u,
  required vm.Vector3 v,
  required vm.Vector3 normal,
  required vm.Vector2 Function(vm.Vector3 worldPosition) uvOf,
}) {
  final p10 = p00 + u;
  final p01 = p00 + v;
  final p11 = p00 + u + v;

  final positions = <double>[];
  final normals = <double>[];
  final uvs = <double>[];
  for (final p in [p00, p10, p01, p11]) {
    positions.addAll([p.x, p.y, p.z]);
    normals.addAll([normal.x, normal.y, normal.z]);
    final uv = uvOf(p);
    uvs.addAll([uv.x, uv.y]);
  }

  return MeshGeometry.fromArrays(
    positions: Float32List.fromList(positions),
    normals: Float32List.fromList(normals),
    texCoords: Float32List.fromList(uvs),
    indices: const [0, 2, 1, 1, 2, 3],
  );
}

/// Builds a node carrying one world-UV-mapped box face mesh per visible
/// side (the four side faces and the top; the bottom is never seen), for a
/// wall segment centered at [center] with the given [halfExtents].
/// [topMaterial] shades the top face and [sideMaterial] the four sides, so a
/// wall's top edge reads distinctly from its sides.
Node _worldUvBoxNode({
  required vm.Vector3 center,
  required vm.Vector3 halfExtents,
  required PhysicallyBasedMaterial topMaterial,
  required PhysicallyBasedMaterial sideMaterial,
}) {
  final topGeometry = _boxTopGeometry(center: center, halfExtents: halfExtents);
  final node = Node()
    ..addComponent(MeshComponent(Mesh(topGeometry, topMaterial)));
  for (final geometry in _boxSideGeometries(
    center: center,
    halfExtents: halfExtents,
  )) {
    node.addComponent(MeshComponent(Mesh(geometry, sideMaterial)));
  }
  return node;
}

/// The box's top face geometry, with world-UV texture coordinates projected
/// onto its own plane so the wood grain reads continuously across a wall's
/// length instead of stretching end-to-end.
MeshGeometry _boxTopGeometry({
  required vm.Vector3 center,
  required vm.Vector3 halfExtents,
}) {
  final hx = halfExtents.x;
  final hy = halfExtents.y;
  final hz = halfExtents.z;
  vm.Vector2 xz(vm.Vector3 p) => vm.Vector2(p.x, p.z) / _woodUvUnitsPerTile;

  return _quadGeometry(
    p00: vm.Vector3(center.x - hx, center.y + hy, center.z - hz),
    u: vm.Vector3(2 * hx, 0, 0),
    v: vm.Vector3(0, 0, 2 * hz),
    normal: vm.Vector3(0, 1, 0),
    uvOf: xz,
  );
}

/// The box's four side face geometries, each with world-UV texture
/// coordinates projected onto that face's own plane. See [_boxTopGeometry].
Iterable<MeshGeometry> _boxSideGeometries({
  required vm.Vector3 center,
  required vm.Vector3 halfExtents,
}) sync* {
  final hx = halfExtents.x;
  final hy = halfExtents.y;
  final hz = halfExtents.z;

  vm.Vector2 zy(vm.Vector3 p) => vm.Vector2(p.z, p.y) / _woodUvUnitsPerTile;
  vm.Vector2 xy(vm.Vector3 p) => vm.Vector2(p.x, p.y) / _woodUvUnitsPerTile;

  // +X.
  yield _quadGeometry(
    p00: vm.Vector3(center.x + hx, center.y - hy, center.z - hz),
    u: vm.Vector3(0, 0, 2 * hz),
    v: vm.Vector3(0, 2 * hy, 0),
    normal: vm.Vector3(1, 0, 0),
    uvOf: zy,
  );
  // -X.
  yield _quadGeometry(
    p00: vm.Vector3(center.x - hx, center.y - hy, center.z - hz),
    u: vm.Vector3(0, 2 * hy, 0),
    v: vm.Vector3(0, 0, 2 * hz),
    normal: vm.Vector3(-1, 0, 0),
    uvOf: zy,
  );
  // +Z.
  yield _quadGeometry(
    p00: vm.Vector3(center.x - hx, center.y - hy, center.z + hz),
    u: vm.Vector3(0, 2 * hy, 0),
    v: vm.Vector3(2 * hx, 0, 0),
    normal: vm.Vector3(0, 0, 1),
    uvOf: xy,
  );
  // -Z.
  yield _quadGeometry(
    p00: vm.Vector3(center.x - hx, center.y - hy, center.z - hz),
    u: vm.Vector3(2 * hx, 0, 0),
    v: vm.Vector3(0, 2 * hy, 0),
    normal: vm.Vector3(0, 0, -1),
    uvOf: xy,
  );
}

/// Builds a flat, world-UV annulus centered at [center]: a round opening of
/// [innerRadius] cut out of an otherwise square (of half-size [halfSize])
/// floor cell, so a hole's or the exit's cup shows through a real gap in
/// the floor instead of the marble rolling over a flat, painted-on circle.
///
/// [segments] divides the ring; the outer boundary follows the square cell
/// edge at each segment's angle rather than a circle, so adjacent opening
/// and non-opening tiles still meet edge-to-edge with no gap.
MeshGeometry _worldUvAnnulus({
  required vm.Vector3 center,
  required double innerRadius,
  double halfSize = 0.5,
  int segments = 24,
}) {
  final positions = <double>[];
  final normals = <double>[];
  final uvs = <double>[];
  final indices = <int>[];

  for (var i = 0; i < segments; i++) {
    final angle = 2 * math.pi * i / segments;
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    final outerT = halfSize / math.max(cos.abs(), sin.abs());

    final innerX = center.x + cos * innerRadius;
    final innerZ = center.z + sin * innerRadius;
    final outerX = center.x + cos * outerT;
    final outerZ = center.z + sin * outerT;

    positions.addAll([innerX, center.y, innerZ, outerX, center.y, outerZ]);
    normals.addAll([0, 1, 0, 0, 1, 0]);
    uvs.addAll([
      innerX / _woodUvUnitsPerTile,
      innerZ / _woodUvUnitsPerTile,
      outerX / _woodUvUnitsPerTile,
      outerZ / _woodUvUnitsPerTile,
    ]);
  }

  for (var i = 0; i < segments; i++) {
    final inner0 = i * 2;
    final outer0 = i * 2 + 1;
    final next = (i + 1) % segments;
    final inner1 = next * 2;
    final outer1 = next * 2 + 1;
    indices.addAll([inner0, outer0, inner1, inner1, outer0, outer1]);
  }

  return MeshGeometry.fromArrays(
    positions: Float32List.fromList(positions),
    normals: Float32List.fromList(normals),
    texCoords: Float32List.fromList(uvs),
    indices: indices,
  );
}
