import 'dart:async';
import 'dart:math' as math;

import 'package:box3d/box3d.dart';
import 'package:level_domain/level_domain.dart';
import 'package:simulation_data_box3d/src/box3d_marble_simulation_config.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:tilt_domain/tilt_domain.dart';
import 'package:vector_math/vector_math.dart';

/// Extra room, in world units, allowed beyond the board's edges before the
/// safety net treats the marble as having left it. Wider than the outer
/// border wall's own thickness, so only a marble that actually clipped
/// through it trips this check.
const _boundsMargin = 1.0;
const _minSensorRadius = 0.01;

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
  int? _marbleShapeHandle;
  Level? _level;
  Duration _accumulated = Duration.zero;

  /// Whether the marble is frozen after falling in a hole or leaving the
  /// board. Cleared by [respawn].
  bool _frozen = false;

  /// Maps a hole sensor shape's handle to the [GridPoint] it triggers for.
  final _holeSensors = <int, GridPoint>{};

  final _eventsController = StreamController<SimulationEvent>.broadcast();

  @override
  void load(Level level) {
    _world?.dispose();
    _level = level;
    _accumulated = Duration.zero;
    _frozen = false;
    _holeSensors.clear();

    final world = Box3dWorld(gravity: Vector3(0, -config.gravityMagnitude, 0));
    _world = world;

    _buildFloor(world, level);
    for (final wall in level.walls) {
      _buildWallRun(world, level, wall);
    }
    _buildBorder(world, level);
    for (final hole in level.holes) {
      _buildHoleSensor(world, level, hole);
    }
    _buildExitSensor(world, level);

    final start = gridPointCenter(
      level.start,
      width: level.width,
      height: level.height,
    )..y = config.marbleRadius;
    final marble = world.createBody(position: start)
      ..isBullet = true
      ..linearDamping = config.linearDamping
      ..angularDamping = config.angularDamping
      ..sleepEnabled = false;
    final marbleShape = marble.addSphere(config.marbleRadius)
      ..sensorEventsEnabled = true;
    _marbleBody = marble;
    _marbleShapeHandle = marbleShape.handle;
  }

  void _buildHoleSensor(Box3dWorld world, Level level, GridPoint hole) {
    final center = gridPointCenter(
      hole,
      width: level.width,
      height: level.height,
    )..y = config.marbleRadius;
    final sensor =
        world
            .createBody(type: Box3dBodyType.static_, position: center)
            .addSphere(
              _sensorRadiusFor(config.holeTriggerRadius),
              isSensor: true,
            )
          ..sensorEventsEnabled = true;
    _holeSensors[sensor.handle] = hole;
  }

  // The exit sensor's shape exists so it can be collided against, but does
  // not enable sensor events: nothing consumes exit overlaps yet.
  void _buildExitSensor(Box3dWorld world, Level level) {
    final center = gridPointCenter(
      level.exit,
      width: level.width,
      height: level.height,
    )..y = config.marbleRadius;
    world
        .createBody(type: Box3dBodyType.static_, position: center)
        .addSphere(_sensorRadiusFor(config.exitTriggerRadius), isSensor: true);
  }

  // box3d reports a sensor overlap as soon as the marble's sphere touches the
  // sensor, but a trigger radius is measured to the marble's centre. Shrinking
  // the sensor by the marble radius makes the two agree.
  double _sensorRadiusFor(double triggerRadius) =>
      math.max(triggerRadius - config.marbleRadius, _minSensorRadius);

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
    if (!_frozen) marble.wakeUp();

    _accumulated += clamped;
    final timestep = Duration(
      microseconds:
          (config.fixedTimestepSeconds * Duration.microsecondsPerSecond)
              .round(),
    );
    while (_accumulated >= timestep) {
      world.step(config.fixedTimestepSeconds);
      _accumulated -= timestep;

      // Drained every fixed step regardless of freeze state, since box3d
      // replaces the event buffers on the next step; while frozen the
      // drained events are simply discarded below.
      final stepEvents = world.drainEvents();
      if (_frozen) continue;

      _handleSensorEvents(stepEvents, marble);
      if (_frozen) continue;

      _checkBounds(marble);
      if (_frozen) continue;

      _clampSpeed(marble);
    }
  }

  void _handleSensorEvents(Box3dEvents stepEvents, Box3dBody marble) {
    final marbleShape = _marbleShapeHandle;
    if (marbleShape == null) return;
    for (final began in stepEvents.sensorBegan) {
      if (began.visitorShape != marbleShape) continue;
      final hole = _holeSensors[began.sensorShape];
      if (hole == null) continue;
      _freeze(marble);
      _eventsController.add(FellInHole(hole));
      return;
    }
  }

  void _checkBounds(Box3dBody marble) {
    final level = _level;
    if (level == null) return;
    final position = marble.position;
    final halfWidth = level.width / 2;
    final halfHeight = level.height / 2;
    final outOfBounds =
        position.x.abs() > halfWidth + _boundsMargin ||
        position.z.abs() > halfHeight + _boundsMargin ||
        position.y < -config.floorThickness;
    final nonFinite =
        !position.x.isFinite || !position.y.isFinite || !position.z.isFinite;
    if (!outOfBounds && !nonFinite) return;
    _freeze(marble);
    _eventsController.add(const LeftBoard());
  }

  void _clampSpeed(Box3dBody marble) {
    final velocity = marble.linearVelocity;
    final speed = velocity.length;
    if (speed <= config.maxSpeed) return;
    marble.linearVelocity = velocity..scale(config.maxSpeed / speed);
  }

  void _freeze(Box3dBody marble) {
    marble
      ..type = Box3dBodyType.kinematic
      ..linearVelocity = Vector3.zero()
      ..angularVelocity = Vector3.zero();
    _frozen = true;
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
      ..type = Box3dBodyType.dynamic_
      ..setTransform(start)
      ..linearVelocity = Vector3.zero()
      ..angularVelocity = Vector3.zero()
      ..wakeUp();
    _frozen = false;
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
      isActive: !_frozen,
    );
  }

  @override
  Stream<SimulationEvent> get events => _eventsController.stream;

  @override
  void dispose() {
    _world?.dispose();
    _world = null;
    _marbleBody = null;
    _marbleShapeHandle = null;
    _holeSensors.clear();
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
