import 'package:level_domain/level_domain.dart';

/// A hard-coded empty square arena, until level files exist.
const arenaLevel = Level(
  id: 'arena',
  title: 'Arena',
  width: _arenaSize,
  height: _arenaSize,
  start: GridPoint(column: 4, row: 4),
  exit: GridPoint(column: 7, row: 7),
  holes: [],
  walls: [
    WallRun(row: 0, startColumn: 0, length: _arenaSize),
    WallRun(row: 1, startColumn: 0, length: 1),
    WallRun(row: 1, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 2, startColumn: 0, length: 1),
    WallRun(row: 2, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 3, startColumn: 0, length: 1),
    WallRun(row: 3, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 4, startColumn: 0, length: 1),
    WallRun(row: 4, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 5, startColumn: 0, length: 1),
    WallRun(row: 5, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 6, startColumn: 0, length: 1),
    WallRun(row: 6, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: 7, startColumn: 0, length: 1),
    WallRun(row: 7, startColumn: _arenaSize - 1, length: 1),
    WallRun(row: _arenaSize - 1, startColumn: 0, length: _arenaSize),
  ],
);

const _arenaSize = 9;
