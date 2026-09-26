import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/animation/marble_sink_animation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The sink animation played when the marble falls into a hole or leaves
/// the board.
const _sinkAnimation = MarbleSinkAnimation();

/// Renders the board and marble with flutter_scene, and drives the frame
/// loop: reads touch drag into a [Tilt], steps [simulation], and updates the
/// scene from it.
///
/// The board root node's rotation is visual only, from the current [Tilt];
/// gravity, not board rotation, drives the physics inside [simulation].
///
/// On a [FellInHole] or [LeftBoard] simulation event, this plays a sink
/// animation on the marble, then calls `simulation.respawn()`. [onMarbleFell]
/// and [onMarbleRespawned] notify the caller of those two moments so it can
/// drive its own state (for example a bloc cubit) without this view knowing
/// about it.
class BoardSceneView extends StatefulWidget {
  /// Creates a board scene view for [level], stepping [simulation] each
  /// frame.
  const new({
    required this.level,
    required this.simulation,
    required this.onMarbleFell,
    required this.onMarbleRespawned,
    super.key,
  });

  /// The level to render and load into [simulation].
  final Level level;

  /// The marble simulation this view steps every frame.
  final IMarbleSimulation simulation;

  /// Called when the marble falls into a hole or leaves the board, before
  /// the sink animation starts.
  final VoidCallback onMarbleFell;

  /// Called once the sink animation completes and `simulation.respawn()`
  /// has been called.
  final VoidCallback onMarbleRespawned;

  @override
  State<BoardSceneView> createState() => _BoardSceneViewState();
}

class _BoardSceneViewState extends State<BoardSceneView>
    with SingleTickerProviderStateMixin {
  final Scene _scene = Scene();
  final TouchTiltMapper _tiltMapper = TouchTiltMapper();
  final Node _boardRoot = Node();
  late final Node _marbleNode;
  Ticker? _ticker;
  StreamSubscription<SimulationEvent>? _eventsSubscription;
  Duration _lastElapsed = Duration.zero;
  Duration? _fallStartElapsed;
  bool _ready = false;

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
      case ReachedExit() || HitWall():
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
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    _tiltMapper.update(delta);
    final tilt = _tiltMapper.tilt;

    // Stepped unconditionally, even while falling: the marble is frozen at
    // that point, so stepping it is harmless.
    widget.simulation.step(tilt, delta);

    _boardRoot.rotation =
        vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -tilt.x) *
        vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -tilt.y);

    if (_isFalling) {
      _updateFallingMarble(elapsed);
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
    _tiltMapper.dragStart(local.dx, local.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;
    _tiltMapper.dragUpdate(local.dx, local.dy);
  }

  void _onPanEnd(DragEndDetails details) => _tiltMapper.dragEnd();

  void _onPanCancel() => _tiltMapper.dragEnd();

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
