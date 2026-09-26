import 'dart:async';
import 'dart:math' as math;

import 'package:box3d/box3d.dart';
import 'package:level_domain/level_domain.dart';
import 'package:simulation_data_box3d/src/box3d_marble_simulation_config.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

/// A [IMarbleSimulation] backed by the box3d physics engine.
///
/// Gravity tilts, not the board: [step] points `world.gravity` at the
/// current [Tilt] each call rather than rotating any body. Physics
/// advances on a fixed internal timestep, keeping the remainder between
/// calls.
class Box3dMarbleSimulation implements IMarbleSimulation, MarbleTestHandle {
  /// Creates a box3d marble simulation with the given tuning.
  new({this.config = Box3dMarbleSimulationConfig.standard});

  /// The tuning this simulation uses.
  final Box3dMarbleSimulationConfig config;

  Box3dWorld? _world;
  Box3dBody? _marbleBody;
  Level? _level;
  Duration _accumulated = Duration.zero;
  final _eventsController = StreamController<SimulationEvent>.broadcast();

  @override
  void load(Level level) {
    _world?.dispose();
    _level = level;
    _accumulated = Duration.zero;

    final world = Box3dWorld(gravity: Vector3(0, -config.gravityMagnitude, 0));
    _world = world;

    _buildFloor(world, level);
    for (final wall in level.walls) {
      _buildWallRun(world, level, wall);
    }
    _buildBorder(world, level);

    final start = gridPointCenter(
      level.start,
      width: level.width,
      height: level.height,
    )..y = config.marbleRadius;
    final marble = world.createBody(position: start)
      ..addSphere(config.marbleRadius)
      ..isBullet = true
      ..linearDamping = config.linearDamping
      ..angularDamping = config.angularDamping
      ..sleepEnabled = false;
    _marbleBody = marble;
  }

  void _buildFloor(Box3dWorld world, Level level) {
    final halfExtents = Vector3(
      level.width / 2,
      config.floorThickness / 2,
      level.height / 2,
    );
    world
        .createBody(
          type: Box3dBodyType.static_,
          position: Vector3(0, -config.floorThickness / 2, 0),
        )
        .addBox(halfExtents);
  }

  void _buildWallRun(Box3dWorld world, Level level, WallRun wall) {
    final placement = wallRunPlacement(
      wall,
      width: level.width,
      height: level.height,
    );
    final halfExtents = Vector3(
      placement.halfLength,
      config.wallHeight / 2,
      0.5,
    );
    final position = Vector3(
      placement.center.x,
      config.wallHeight / 2,
      placement.center.z,
    );
    world
        .createBody(type: Box3dBodyType.static_, position: position)
        .addBox(halfExtents);
  }

  void _buildBorder(Box3dWorld world, Level level) {
    final halfWidth = level.width / 2;
    final halfHeight = level.height / 2;
    final halfWallHeight = config.wallHeight / 2;
    final halfThickness = config.wallThickness / 2;

    void addBorderBox(Vector3 center, Vector3 halfExtents) {
      world
          .createBody(type: Box3dBodyType.static_, position: center)
          .addBox(halfExtents);
    }

    addBorderBox(
      Vector3(0, halfWallHeight, -halfHeight - halfThickness),
      Vector3(halfWidth + config.wallThickness, halfWallHeight, halfThickness),
    );
    addBorderBox(
      Vector3(0, halfWallHeight, halfHeight + halfThickness),
      Vector3(halfWidth + config.wallThickness, halfWallHeight, halfThickness),
    );
    addBorderBox(
      Vector3(-halfWidth - halfThickness, halfWallHeight, 0),
      Vector3(halfThickness, halfWallHeight, halfHeight + config.wallThickness),
    );
    addBorderBox(
      Vector3(halfWidth + halfThickness, halfWallHeight, 0),
      Vector3(halfThickness, halfWallHeight, halfHeight + config.wallThickness),
    );
  }

  @override
  void step(Tilt tilt, Duration elapsed) {
    final world = _world;
    final marble = _marbleBody;
    if (world == null || marble == null) return;

    final clamped = elapsed > config.maxStepElapsed
        ? config.maxStepElapsed
        : elapsed;
    world.gravity = _gravityFor(tilt);
    marble.wakeUp();

    _accumulated += clamped;
    final timestep = Duration(
      microseconds:
          (config.fixedTimestepSeconds * Duration.microsecondsPerSecond)
              .round(),
    );
    while (_accumulated >= timestep) {
      world.step(config.fixedTimestepSeconds);
      _accumulated -= timestep;
    }
  }

  Vector3 _gravityFor(Tilt tilt) {
    final g = config.gravityMagnitude;
    return Vector3(
      g * math.sin(tilt.x),
      -g * math.cos(tilt.x) * math.cos(tilt.y),
      -g * math.sin(tilt.y),
    );
  }

  @override
  void respawn() {
    final level = _level;
    final marble = _marbleBody;
    if (level == null || marble == null) return;
    final start = gridPointCenter(
      level.start,
      width: level.width,
      height: level.height,
    )..y = config.marbleRadius;
    marble
      ..setTransform(start)
      ..linearVelocity = Vector3.zero()
      ..angularVelocity = Vector3.zero()
      ..wakeUp();
  }

  @override
  MarbleState get marble {
    final body = _marbleBody;
    if (body == null) {
      return MarbleState(
        position: Vector3.zero(),
        rotation: Quaternion.identity(),
        velocity: Vector3.zero(),
        isActive: false,
      );
    }
    return MarbleState(
      position: body.position,
      rotation: body.rotation,
      velocity: body.linearVelocity,
      isActive: true,
    );
  }

  @override
  Stream<SimulationEvent> get events => _eventsController.stream;

  @override
  void dispose() {
    _world?.dispose();
    _world = null;
    _marbleBody = null;
    unawaited(_eventsController.close());
  }

  @override
  void placeMarble(Vector3 position) {
    _marbleBody
      ?..setTransform(position)
      ..wakeUp();
  }

  @override
  void setMarbleVelocity(Vector3 velocity) {
    _marbleBody
      ?..linearVelocity = velocity
      ..wakeUp();
  }
}
