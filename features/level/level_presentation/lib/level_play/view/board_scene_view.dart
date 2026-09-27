import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/animation/marble_sink_animation.dart';
import 'package:level_presentation/level_play/input/level_play_input_controller.dart';
import 'package:level_presentation/level_play/view/frame_clock.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The sink animation played when the marble falls into a hole or leaves
/// the board.
const _sinkAnimation = MarbleSinkAnimation();

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
  Ticker? _ticker;
  StreamSubscription<SimulationEvent>? _eventsSubscription;
  final FrameClock _frameClock = FrameClock();
  Duration? _fallStartElapsed;
  bool _ready = false;

  // An alias so the fall-start timestamp below reads (and freezes while
  // paused) from the clock's active-only elapsed time, rather than
  // wall-clock ticker time.
  Duration get _lastElapsed => _frameClock.activeElapsed;

  bool get _isFalling => _fallStartElapsed != null;

  @override
  void initState() {
    super.initState();
    widget.simulation.load(widget.level);
    _eventsSubscription = widget.simulation.events.listen(_onSimulationEvent);
    unawaited(_buildScene());
  }

  void _onSimulationEvent(SimulationEvent event) {
    if (_isFalling) return;
    switch (event) {
      case FellInHole() || LeftBoard():
        _fallStartElapsed = _lastElapsed;
        widget.onMarbleFell();
      case ReachedExit():
        widget.onReachedExit();
      case HitWall():
        break;
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
          ..metallicFactor = 0.9
          ..roughnessFactor = 0.2,
      ),
    );
    _scene
      ..add(_boardRoot)
      ..add(_marbleNode);

    if (!mounted) return;
    setState(() => _ready = true);
    _ticker = createTicker(_onTick)..start();
  }

  void _buildBoard() {
    final level = widget.level;
    final floor = Node(
      mesh: Mesh(
        CuboidGeometry(
          vm.Vector3(level.width.toDouble(), 0.2, level.height.toDouble()),
        ),
        PhysicallyBasedMaterial()..roughnessFactor = 0.8,
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
                PhysicallyBasedMaterial()..roughnessFactor = 0.6,
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
        _buildFloorMarker(hole, radius: kHoleRadius, level: level),
      );
    }
    _boardRoot.add(
      _buildFloorMarker(
        level.exit,
        radius: kExitRadius,
        level: level,
        color: Colors.amber,
      ),
    );
  }

  static const _holeMarkerColor = Color(0xFF141414);

  // A thin disc set into the floor: proper cups and materials come in #10,
  // this is only so the player can see where holes and the exit are.
  Node _buildFloorMarker(
    GridPoint point, {
    required double radius,
    required Level level,
    Color color = _holeMarkerColor,
  }) {
    final center = gridPointCenter(
      point,
      width: level.width,
      height: level.height,
    );
    return Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: radius, topRadius: radius, height: 0.02),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(color.r, color.g, color.b, color.a)
          ..roughnessFactor = 0.9,
      ),
    )..position = vm.Vector3(center.x, 0.01, center.z);
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
        vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -tilt.y);

    if (_isFalling) {
      _updateFallingMarble(_frameClock.activeElapsed);
    } else {
      final marble = widget.simulation.marble;
      _marbleNode
        ..position = marble.position
        ..rotation = marble.rotation
        ..scale = vm.Vector3.all(1);
    }
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
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: SceneView(
        _scene,
        camera: PerspectiveCamera(
          position: vm.Vector3(0, 8, -6),
          target: vm.Vector3(0, 0, 0),
        ),
      ),
    );
  }
}
