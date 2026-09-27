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
import 'package:level_presentation/level_play/view/frame_clock.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';
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

/// The touch tilt's contribution to the board's visual rotation, scaled
/// down from a full physical tilt since it is only a touch-mode cue: with
/// the accelerometer, the phone itself is the board, so the rendered board
/// must stay fixed to the screen.
const double _visualTiltScale = 0.5;

/// Renders the board and marble with flutter_scene, and drives the frame
/// loop: reads the current tilt from [controller], steps [simulation], and
/// updates the scene from it.
///
/// The board stays fixed to the screen: with the accelerometer, the phone
/// itself is the board, so the rendered board does not rotate with the
/// physical tilt.
/// The board root node's rotation instead follows [controller]'s
/// `visualTilt`, a small, scaled-down touch-mode cue shown only while a
/// finger is down or easing back to flat after release. Gravity, not board
/// rotation, drives the physics inside [simulation] either way.
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
  double _cameraZ = 0;
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
      position: vm.Vector3(0, 8, -6),
      target: vm.Vector3(0, 0, 0),
    );
    _scene
      ..add(_boardRoot)
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, 0.5),
        castsShadow: true,
      )
      // A patterned, non-metallic marble no longer needs a mirror highlight
      // bloomed out; disabled so it doesn't wash out the swirl texture.
      ..postProcess.bloom.enabled = false;
    unawaited(_scene.loadEnvironment(_environmentAsset));

    if (!mounted) return;
    setState(() => _ready = true);
    _ticker = createTicker(_onTick)..start();
  }

  static const Color _cupColor = Color(0xFF141414);
  static const Color _exitCupColor = Colors.amber;

  /// `doubleSided` since floor tiles, opening rings, and wall faces are
  /// hand-built flat quads (see [_quadGeometry]); getting every face's
  /// winding order exactly right for backface culling is unnecessary risk
  /// for geometry this thin.
  static PhysicallyBasedMaterial _woodMaterial(Texture2D texture) =>
      PhysicallyBasedMaterial()
        ..baseColorTexture = texture
        ..metallicFactor = 0
        ..roughnessFactor = 0.75
        ..doubleSided = true;

  void _buildBoard(Texture2D woodTexture) {
    final level = widget.level;
    final wood = _woodMaterial(woodTexture);
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
          material: wood,
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

    // The board stays fixed to the screen except for this small visual
    // tilt, a touch-mode cue rather than a physical rotation: with the
    // accelerometer, the phone itself is the board, so rotating it to match
    // [tilt] (which the marble's physics actually uses) would double-tilt
    // it from the player's point of view.
    final visualTilt = widget.controller.visualTilt;
    _boardRoot.rotation =
        vm.Quaternion.axisAngle(
          vm.Vector3(0, 0, 1),
          -visualTilt.x * _visualTiltScale,
        ) *
        vm.Quaternion.axisAngle(
          vm.Vector3(1, 0, 0),
          visualTilt.y * _visualTiltScale,
        );

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
    _updateCamera(delta);
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

  /// Advances the camera's Z target toward the marble (or the exit cup,
  /// once won) and toward the board's center on a level that fits on
  /// screen, smoothing frame-rate independently.
  void _updateCamera(Duration delta) {
    final level = widget.level;
    final marbleZ = widget.simulation.marble.position.z;
    final targetZ = _boardCamera.targetZFor(
      marbleZ: marbleZ,
      boardWidth: level.width.toDouble(),
      boardHeight: level.height.toDouble(),
      viewportAspectRatio: _viewportAspectRatio,
    );
    _cameraZ = _boardCamera.smoothTowards(_cameraZ, targetZ, delta);

    final distance = _boardCamera.distanceToFit(
      level.width.toDouble(),
      _viewportAspectRatio,
    );
    final horizontalOffset = distance * math.cos(_boardCamera.pitchRadians);
    final verticalOffset = distance * math.sin(_boardCamera.pitchRadians);
    _camera
      ..position = vm.Vector3(0, verticalOffset, _cameraZ - horizontalOffset)
      ..target = vm.Vector3(0, 0, _cameraZ);
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
          _viewportAspectRatio = constraints.maxWidth / constraints.maxHeight;
        }
        return GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: SceneView(_scene, camera: _camera),
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
Node _worldUvBoxNode({
  required vm.Vector3 center,
  required vm.Vector3 halfExtents,
  required PhysicallyBasedMaterial material,
}) {
  final node = Node();
  for (final geometry in _boxFaceGeometries(
    center: center,
    halfExtents: halfExtents,
  )) {
    node.addComponent(MeshComponent(Mesh(geometry, material)));
  }
  return node;
}

/// The top and four side face geometries of a box, each with world-UV
/// texture coordinates projected onto that face's own plane, so the wood
/// grain reads continuously across a wall's length instead of stretching
/// end-to-end.
Iterable<MeshGeometry> _boxFaceGeometries({
  required vm.Vector3 center,
  required vm.Vector3 halfExtents,
}) sync* {
  final hx = halfExtents.x;
  final hy = halfExtents.y;
  final hz = halfExtents.z;

  vm.Vector2 xz(vm.Vector3 p) => vm.Vector2(p.x, p.z) / _woodUvUnitsPerTile;
  vm.Vector2 zy(vm.Vector3 p) => vm.Vector2(p.z, p.y) / _woodUvUnitsPerTile;
  vm.Vector2 xy(vm.Vector3 p) => vm.Vector2(p.x, p.y) / _woodUvUnitsPerTile;

  // Top (+Y).
  yield _quadGeometry(
    p00: vm.Vector3(center.x - hx, center.y + hy, center.z - hz),
    u: vm.Vector3(2 * hx, 0, 0),
    v: vm.Vector3(0, 0, 2 * hz),
    normal: vm.Vector3(0, 1, 0),
    uvOf: xz,
  );
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
