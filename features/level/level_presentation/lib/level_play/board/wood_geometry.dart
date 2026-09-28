import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/board/wall_strip.dart';
import 'package:meta/meta.dart';
import 'package:simulation_domain/simulation_domain.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Maps the board's wood surfaces onto one shared sheet of wood texture.
///
/// The floor samples the sheet once across the whole board, centered on the
/// origin, with the texture's grain (its V axis) running along world Z, the
/// board's long axis. Wall strips sample the same sheet at the same density
/// but from their own [WallStrip.grainOffset], with the grain along their
/// length.
@immutable
class WoodSheet {
  /// Creates a wood sheet covering [unitsPerTexture] world units per texture
  /// repeat.
  const new({this.unitsPerTexture = 24});

  /// How many world units one repeat of the texture spans. The default
  /// covers the largest bundled level (22 cells) without repeating.
  final double unitsPerTexture;

  /// The floor's texture coordinate at world position ([x], [z]).
  vm.Vector2 floorUv(double x, double z) =>
      vm.Vector2(x / unitsPerTexture + 0.5, z / unitsPerTexture + 0.5);

  /// A wall strip's texture coordinate at [across] units across its surface
  /// and [along] units along its length, starting at [offset].
  vm.Vector2 stripUv(double across, double along, vm.Vector2 offset) =>
      vm.Vector2(
        across / unitsPerTexture + offset.x,
        along / unitsPerTexture + offset.y,
      );
}

/// A flat, `+Y`-facing floor quad of half-size [halfSize] centered at
/// [center], textured from [sheet].
MeshGeometry floorTileGeometry({
  required vm.Vector3 center,
  required WoodSheet sheet,
  double halfSize = 0.5,
}) {
  final corners = [
    vm.Vector3(center.x - halfSize, center.y, center.z - halfSize),
    vm.Vector3(center.x + halfSize, center.y, center.z - halfSize),
    vm.Vector3(center.x + halfSize, center.y, center.z + halfSize),
    vm.Vector3(center.x - halfSize, center.y, center.z + halfSize),
  ];
  return (_MeshBuilder()..addPolygon(
        corners,
        normal: vm.Vector3(0, 1, 0),
        uvs: [for (final p in corners) sheet.floorUv(p.x, p.z)],
      ))
      .build();
}

/// A flat floor cell with a round opening of [innerRadius] cut out of its
/// center, so a hole's or the exit's cup shows through a real gap in the
/// floor instead of the marble rolling over a painted-on circle.
///
/// [segments] divides the ring; the outer boundary follows the square cell
/// edge at each segment's angle rather than a circle, so adjacent opening
/// and non-opening cells still meet edge-to-edge with no gap.
MeshGeometry floorOpeningGeometry({
  required vm.Vector3 center,
  required double innerRadius,
  required WoodSheet sheet,
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
    final innerUv = sheet.floorUv(innerX, innerZ);
    final outerUv = sheet.floorUv(outerX, outerZ);

    positions.addAll([innerX, center.y, innerZ, outerX, center.y, outerZ]);
    normals.addAll([0, 1, 0, 0, 1, 0]);
    uvs.addAll([innerUv.x, innerUv.y, outerUv.x, outerUv.y]);
  }

  for (var i = 0; i < segments; i++) {
    final inner0 = i * 2;
    final outer0 = i * 2 + 1;
    final next = (i + 1) % segments;
    final inner1 = next * 2;
    final outer1 = next * 2 + 1;
    indices.addAll([inner0, inner1, outer0, inner1, outer1, outer0]);
  }

  return MeshGeometry.fromArrays(
    positions: Float32List.fromList(positions),
    normals: Float32List.fromList(normals),
    texCoords: Float32List.fromList(uvs),
    indices: indices,
  );
}

/// The board's walls as two meshes: `top` (the flat tops, the bevels, and
/// the inside-corner pieces) and `sides` (the vertical faces). Kept apart so
/// each can take its own material.
typedef WallGeometry = ({MeshGeometry top, MeshGeometry sides});

/// Builds every wall in [strips] as one solid, [wallHeight] tall, on a
/// board [width] by [height] cells.
///
/// Built cell by cell from the grid rather than strip by strip, so walls
/// that touch merge with no groove at the joint:
///
///  * A cell only gets a side face and a [bevel]-sized 45° chamfer on an
///    edge that faces open floor; where it meets another wall cell, its flat
///    top runs straight across.
///  * Where two chamfers meet at an outside corner, they're mitred.
///  * At an inside corner (two wall neighbours with open floor diagonally
///    between them) the corner cell gets a small valley so the neighbours'
///    chamfers meet cleanly.
///
/// Each cell takes its strip's grain direction and offset (see
/// [WallStrip]), so a joint between strips shows only as a change in
/// grain, like two glued boards.
WallGeometry wallGeometry(
  List<WallStrip> strips, {
  required int width,
  required int height,
  required double wallHeight,
  required WoodSheet sheet,
  double bevel = 0.08,
}) {
  final stripByCell = {
    for (final strip in strips)
      for (final cell in strip.cells) cell: strip,
  };
  final top = _MeshBuilder();
  final sides = _MeshBuilder();

  for (final MapEntry(key: cell, value: strip) in stripByCell.entries) {
    // Beyond the board's edge counts as wall: nothing there is ever seen,
    // so the outermost walls need no faces or chamfers facing outwards.
    bool isWall(int dx, int dz) {
      final column = cell.column + dx;
      final row = cell.row - dz;
      final outside = column < 0 || row < 0 || column >= width || row >= height;
      return outside ||
          stripByCell.containsKey(GridPoint(column: column, row: row));
    }

    _WallCell(
      center: gridCellCenter(
        cell.column,
        cell.row,
        width: width,
        height: height,
      ),
      strip: strip,
      isWall: isWall,
      wallHeight: wallHeight,
      bevel: bevel,
      sheet: sheet,
    ).build(top: top, sides: sides);
  }

  return (top: top.build(), sides: sides.build());
}

/// One wall cell's faces. Local coordinates are relative to the cell's
/// center, with each axis running from `-0.5` to `0.5`.
class _WallCell {
  new({
    required this.center,
    required this.strip,
    required this.isWall,
    required this.wallHeight,
    required this.bevel,
    required this.sheet,
  });

  static const _edges = [(1, 0), (-1, 0), (0, 1), (0, -1)];

  final vm.Vector3 center;
  final WallStrip strip;

  /// Whether the cell `dx` columns and `dz` world-Z steps away is a wall.
  final bool Function(int dx, int dz) isWall;
  final double wallHeight;
  final double bevel;
  final WoodSheet sheet;

  double get _bevelBottom => wallHeight - bevel;

  void build({required _MeshBuilder top, required _MeshBuilder sides}) {
    _addTop(top);
    for (final (nx, nz) in _edges) {
      if (isWall(nx, nz)) continue;
      _addBevel(top, nx, nz);
      _addSide(sides, nx, nz);
    }
    for (final sx in const [-1, 1]) {
      for (final sz in const [-1, 1]) {
        if (_isInsideCorner(sx, sz)) _addInsideCorner(top, sx, sz);
      }
    }
  }

  bool _isInsideCorner(int sx, int sz) =>
      isWall(sx, 0) && isWall(0, sz) && !isWall(sx, sz);

  /// The flat top, inset by the chamfer on every open edge, and with the
  /// chamfer-sized square cut out of every inside corner.
  void _addTop(_MeshBuilder builder) {
    const edge = 0.5;
    final inset = edge - bevel;
    final x0 = isWall(-1, 0) ? -edge : -inset;
    final x1 = isWall(1, 0) ? edge : inset;
    final z0 = isWall(0, -1) ? -edge : -inset;
    final z1 = isWall(0, 1) ? edge : inset;
    final xs = {x0, if (x0 == -edge) -inset, if (x1 == edge) inset, x1}.toList()
      ..sort();
    final zs = {z0, if (z0 == -edge) -inset, if (z1 == edge) inset, z1}.toList()
      ..sort();

    for (var i = 0; i < xs.length - 1; i++) {
      for (var j = 0; j < zs.length - 1; j++) {
        final midX = (xs[i] + xs[i + 1]) / 2;
        final midZ = (zs[j] + zs[j + 1]) / 2;
        final inCornerSquare = midX.abs() > inset && midZ.abs() > inset;
        if (inCornerSquare &&
            _isInsideCorner(midX.sign.toInt(), midZ.sign.toInt())) {
          continue;
        }
        _addTopFace(builder, [
          vm.Vector3(xs[i], wallHeight, zs[j]),
          vm.Vector3(xs[i + 1], wallHeight, zs[j]),
          vm.Vector3(xs[i + 1], wallHeight, zs[j + 1]),
          vm.Vector3(xs[i], wallHeight, zs[j + 1]),
        ], normal: vm.Vector3(0, 1, 0));
      }
    }
  }

  /// The chamfer along the open edge facing ([nx], [nz]). Each end is
  /// mitred where the neighbouring edge is open too (an outside corner), and
  /// otherwise runs to the cell's border to meet the next cell's chamfer or
  /// an inside corner's valley.
  void _addBevel(_MeshBuilder builder, int nx, int nz) {
    final normal = vm.Vector3(nx.toDouble(), 0, nz.toDouble());
    final along = vm.Vector3(-nz.toDouble(), 0, nx.toDouble());
    final corners = <vm.Vector3>[];
    for (final end in const [-1, 1]) {
      final bottom = normal * 0.5 + along * (end * 0.5)
        ..y = _bevelBottom;
      corners.add(bottom);
    }
    for (final end in const [1, -1]) {
      final isMitred = !isWall(-nz * end, nx * end);
      final reach = isMitred ? 0.5 - bevel : 0.5;
      final top = normal * (0.5 - bevel) + along * (end * reach)
        ..y = wallHeight;
      corners.add(top);
    }
    _addTopFace(
      builder,
      corners,
      normal: vm.Vector3(nx.toDouble(), 1, nz.toDouble())..normalize(),
    );
  }

  /// The valley where the chamfers of the two walls either side of an
  /// inside corner at ([sx], [sz]) meet: two triangles, each continuing one
  /// neighbour's chamfer plane.
  void _addInsideCorner(_MeshBuilder builder, int sx, int sz) {
    final inset = 0.5 - bevel;
    final inner = vm.Vector3(sx * inset, wallHeight, sz * inset);
    final corner = vm.Vector3(sx * 0.5, _bevelBottom, sz * 0.5);
    final onXBorder = vm.Vector3(sx * 0.5, wallHeight, sz * inset);
    final onZBorder = vm.Vector3(sx * inset, wallHeight, sz * 0.5);
    _addTopFace(builder, [
      inner,
      onXBorder,
      corner,
    ], normal: vm.Vector3(0, 1, sz.toDouble())..normalize());
    _addTopFace(builder, [
      inner,
      corner,
      onZBorder,
    ], normal: vm.Vector3(sx.toDouble(), 1, 0)..normalize());
  }

  /// The vertical face below the chamfer on the open edge facing ([nx],
  /// [nz]).
  void _addSide(_MeshBuilder builder, int nx, int nz) {
    final normal = vm.Vector3(nx.toDouble(), 0, nz.toDouble());
    final along = vm.Vector3(-nz.toDouble(), 0, nx.toDouble());
    final local = [
      for (final (end, y) in [
        (-1, 0.0),
        (1, 0.0),
        (1, _bevelBottom),
        (-1, _bevelBottom),
      ])
        normal * 0.5 + along * (end * 0.5)
          ..y = y,
    ];
    final world = [for (final p in local) p + center];
    // A face running along the strip shows its grain lengthways, with the
    // height unrolled across it; one across the strip's end shows the cross
    // grain.
    final runsAlongStrip = strip.runsAlongZ ? nx != 0 : nz != 0;
    builder.addPolygon(
      world,
      normal: normal,
      uvs: [
        for (final p in world)
          if (runsAlongStrip)
            sheet.stripUv(p.y, _along(p), strip.grainOffset)
          else
            sheet.stripUv(_across(p), _along(p) + p.y, strip.grainOffset),
      ],
    );
  }

  /// Adds a face seen from above, textured by projecting straight down onto
  /// the strip's grain.
  void _addTopFace(
    _MeshBuilder builder,
    List<vm.Vector3> local, {
    required vm.Vector3 normal,
  }) {
    final world = [for (final p in local) p + center];
    builder.addPolygon(
      world,
      normal: normal,
      uvs: [
        for (final p in world)
          sheet.stripUv(_across(p), _along(p), strip.grainOffset),
      ],
    );
  }

  double _along(vm.Vector3 world) =>
      strip.runsAlongZ ? world.z - strip.center.z : world.x - strip.center.x;

  double _across(vm.Vector3 world) =>
      strip.runsAlongZ ? world.x - strip.center.x : world.z - strip.center.z;
}

/// Accumulates flat convex polygons into one [MeshGeometry].
///
/// Each polygon is wound so its triangles face along its given normal:
/// `doubleSided` materials still flip the shading normal of a triangle they
/// see from behind, so a polygon wound the wrong way would shade as though
/// it faced away from the light.
class _MeshBuilder {
  final _positions = <double>[];
  final _normals = <double>[];
  final _uvs = <double>[];
  final _indices = <int>[];

  void addPolygon(
    List<vm.Vector3> corners, {
    required vm.Vector3 normal,
    required List<vm.Vector2> uvs,
  }) {
    final facing = (corners[1] - corners[0]).cross(corners[2] - corners[0]);
    final order = facing.dot(normal) >= 0
        ? [for (var i = 0; i < corners.length; i++) i]
        : [for (var i = corners.length - 1; i >= 0; i--) i];

    final first = _positions.length ~/ 3;
    for (final i in order) {
      final p = corners[i];
      _positions.addAll([p.x, p.y, p.z]);
      _normals.addAll([normal.x, normal.y, normal.z]);
      _uvs.addAll([uvs[i].x, uvs[i].y]);
    }
    for (var i = 1; i < corners.length - 1; i++) {
      _indices.addAll([first, first + i, first + i + 1]);
    }
  }

  MeshGeometry build() => MeshGeometry.fromArrays(
    positions: Float32List.fromList(_positions),
    normals: Float32List.fromList(_normals),
    texCoords: Float32List.fromList(_uvs),
    indices: _indices,
  );
}
