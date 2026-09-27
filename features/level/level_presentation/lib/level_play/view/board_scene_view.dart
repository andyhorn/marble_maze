import 'dart:async';
import 'dart:math' as math;

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

/// Renders the board and marble with flutter_scene, and drives the frame
/// loop: reads the current tilt from [controller], steps [simulation], and
/// updates the scene from it.
///
/// The board root node's rotation is visual only, from the current tilt;
/// gravity, not board rotation, drives the physics inside [simulation].
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
      case FellInHole() || LeftBoard():
        _fallStartElapsed = _lastElapsed;
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
      case HapticImpact.light:
        _lastWallHitImpactElapsed = _lastElapsed;
        unawaited(HapticFeedback.lightImpact());
      case HapticImpact.medium:
        unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _buildScene() async {
    // Geometry and materials need the shader bundle, which is only
    // available once the engine's static resources are loaded.
    await Scene.initializeStaticResources();

    _buildBoard();
    _marbleNode = Node(
      mesh: Mesh(
        SphereGeometry(radius: kMarbleRadius),
        PhysicallyBasedMaterial()
          ..metallicFactor = 1
          ..roughnessFactor = 0.12,
      ),
    );
    _camera = PerspectiveCamera(
      position: vm.Vector3(0, 8, -6),
      target: vm.Vector3(0, 0, 0),
    );
    _scene
      ..add(_boardRoot)
      ..add(_marbleNode)
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, 0.5),
        castsShadow: true,
      )
      ..postProcess.bloom.enabled = true
      ..postProcess.bloom.intensity = 0.08;
    unawaited(_scene.loadEnvironment(_environmentAsset));

    if (!mounted) return;
    setState(() => _ready = true);
    _ticker = createTicker(_onTick)..start();
  }

  static const Color _woodColor = Colors.brown;
  static const Color _cupColor = Color(0xFF141414);
  static const Color _exitCupColor = Colors.amber;

  static PhysicallyBasedMaterial _woodMaterial() => PhysicallyBasedMaterial()
    ..baseColorFactor = _colorToVector4(_woodColor)
    ..roughnessFactor = 0.75;

  void _buildBoard() {
    final level = widget.level;
    final floor = Node(
      mesh: Mesh(
        CuboidGeometry(
          vm.Vector3(level.width.toDouble(), 0.2, level.height.toDouble()),
        ),
        _woodMaterial(),
      ),
    )..position = vm.Vector3(0, -0.1, 0);
    _boardRoot.add(floor);

    for (final wall in level.walls) {
      final placement = wallRunPlacement(
        wall,
        width: level.width,
        height: level.height,
      );
      final wallNode =
          Node(
              mesh: Mesh(
                CuboidGeometry(
                  vm.Vector3(placement.halfLength * 2, kWallHeight, 1),
                ),
                _woodMaterial(),
              ),
            )
            ..position = vm.Vector3(
              placement.center.x,
              kWallHeight / 2,
              placement.center.z,
            );
      _boardRoot.add(wallNode);
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

  /// A short, dark cylinder standing in for a cup set into the floor: the
  /// floor is a single solid box with its top surface at world Y 0, so a
  /// collider actually recessed below it would be hidden inside the floor
  /// mesh. This sits flush with the floor instead of visibly recessed.
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
        CylinderGeometry(bottomRadius: radius, topRadius: radius, height: 0.04),
        PhysicallyBasedMaterial()
          ..baseColorFactor = _colorToVector4(color)
          ..metallicFactor = 0
          ..roughnessFactor = 0.85,
      ),
    )..position = vm.Vector3(center.x, 0.02, center.z);
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

    _boardRoot.rotation =
        vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -tilt.x) *
        vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), tilt.y);

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
    if (fallStart == null) return;
    final sinceFall = elapsed - fallStart;

    if (_sinkAnimation.isCompleteAt(sinceFall)) {
      widget.simulation.respawn();
      _fallStartElapsed = null;
      widget.onMarbleRespawned();
      final respawned = widget.simulation.marble;
      _marbleNode
        ..position = respawned.position
        ..rotation = respawned.rotation
        ..scale = vm.Vector3.all(1);
      return;
    }

    final marble = widget.simulation.marble;
    final offset = vm.Vector3(0, _sinkAnimation.sinkOffsetAt(sinceFall), 0);
    _marbleNode
      ..position = marble.position - offset
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
