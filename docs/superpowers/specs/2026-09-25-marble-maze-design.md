# Marble Maze — Design

**Date:** 2026-09-25
**Status:** Approved in brainstorming, pending spec review

## Summary

A 3D tilt-the-board marble maze for iOS and Android, in the style of the classic wooden Labyrinth game. The player tilts the phone (or drags on screen) to roll a steel marble through a grid maze, avoiding holes, to reach the exit as fast as possible.

Built with Flutter, `flutter_scene` for rendering, and the `box3d` physics package, structured as a Feature-First Clean Architecture (FFCA) monorepo.

## Goals

- A playable, polished v1 with a handful of hand-authored levels.
- Tilt control that feels good on a real phone.
- Learn `flutter_scene` and `box3d` ahead of a possible second game (ragdoll cannon).
- Keep the physics engine swappable: if `box3d` does not work out, replace it with custom physics without touching rendering, input, or game flow.

## Non-goals (v1)

- Web and desktop builds.
- Sound and music.
- Moving hazards, bumpers, switches, collectibles.
- A level editor.
- A settings screen (input source is automatic, sensitivity is fixed).
- Cloud saves, accounts, leaderboards.

## Platforms and toolchain

- iOS and Android only. Portrait orientation locked.
- Flutter 3.47+ stable (the `flutter_scene` 0.23 minimum).
- Flutter GPU must be enabled once per platform: an `Info.plist` key on iOS and an `AndroidManifest.xml` meta-data entry on Android.
- Very Good CLI templates for every package; Dart workspace (`resolution: workspace`); Melos for cross-package scripts.

## Gameplay

### Rules

- One marble, one start cell, one exit cell per level.
- Falling into a hole plays a sink animation (~0.5 s) and respawns the marble at the start. The timer keeps running; holes cost time, not lives.
- Reaching the exit ends the level. The score is elapsed time. Each level may define a par time.
- Best time per level is saved locally.

### Flow

1. **Level select**: list of levels with best time and a par indicator.
2. **Ready**: "Tap to start" overlay. The tap also calibrates tilt. Timer starts.
3. **Playing**: HUD shows elapsed time, level title, and a pause button.
4. **Fell**: sink animation, respawn, back to Playing.
5. **Won**: marble drops into the exit cup; overlay shows time, par, best, and Next / Retry / Levels.
6. **Paused**: via the pause button, or automatically when the app goes to the background.

### Haptics

Light impact on wall hits above a speed threshold; medium impact on falling into a hole. Uses Flutter's `HapticFeedback`.

## Level format

Levels are ASCII grid assets in `level_data`, listed in order by a `levels.json` manifest.

```
# title: First Roll
# par: 20
###########
#S....#...#
#.###.#.#.#
#...#...#O#
###.#####.#
#O........#
#.#######.#
#........E#
###########
```

| Char | Meaning |
|---|---|
| `#` | Wall |
| `.` | Floor |
| `S` | Start (exactly one) |
| `E` | Exit (exactly one) |
| `O` | Hole (floor cell with a hole in it) |

- Header lines of the form `# key: value` precede the grid. `title` is required; `par` (seconds, positive integer) is optional.
- All grid rows have equal width.
- Parsing fails with a `LevelFormatException` carrying file, line, column, and reason for: missing or duplicate `S`/`E`, ragged rows, unknown characters, missing `title`, invalid `par`.
- Row 0 of the grid is the far edge of the board (top of the screen).

### World dimensions

- 1 grid cell = 1 world unit. The board lies in the X/Z plane; Y is up.
- Marble radius 0.3. Hole trigger radius 0.4. Wall height 0.6. Exit trigger radius 0.35.
- Horizontal runs of adjacent wall cells merge into a single box collider.

## Architecture

### Monorepo layout

```
marble_maze/
├── apps/
│   └── marble_maze_app/                  # Flutter app: routing, DI assembly, platform config
├── features/
│   ├── level/
│   │   ├── level_domain/                 # Dart
│   │   ├── level_data/                   # Dart (+ level assets)
│   │   └── level_presentation/           # Flutter
│   ├── simulation/                       # headless
│   │   ├── simulation_domain/            # Dart
│   │   └── simulation_data_box3d/        # Dart
│   ├── tilt/                             # headless
│   │   ├── tilt_domain/                  # Dart
│   │   └── tilt_data_sensors_plus/       # Flutter (sensors_plus is a plugin)
│   └── progress/                         # headless
│       ├── progress_domain/              # Dart
│       └── progress_data_shared_preferences/  # Flutter
├── shared/
│   ├── ui_kit/                           # Flutter: theme, buttons, overlay panels
│   └── localizations/                    # Flutter
├── docs/
└── pubspec.yaml                          # workspace root
```

### Dependency graph

- `level_data` → `level_domain`
- `simulation_domain` → `level_domain`, `tilt_domain` (domain-to-domain: `load(Level)`, `step(Tilt, …)`)
- `simulation_data_box3d` → `simulation_domain`, `level_domain`, `tilt_domain`, `box3d`
- `tilt_data_sensors_plus` → `tilt_domain`, `sensors_plus`
- `progress_data_shared_preferences` → `progress_domain`, `shared_preferences`
- `level_presentation` → `level_domain`, `simulation_domain`, `tilt_domain`, `progress_domain`, `ui_kit`, `localizations`, `flutter_scene`, `flutter_bloc`
- `marble_maze_app` → all presentation and data packages, `ui_kit`, `localizations`, `go_router`

No presentation package imports a data package. Shared packages import no features.

### Feature: level

**`level_domain`**

- `Level`: `id`, `title`, `par` (nullable `Duration`), `width`, `height`, `start` (`GridPoint`), `exit` (`GridPoint`), `holes` (`List<GridPoint>`), `walls` (`List<WallRun>`).
- `GridPoint`: `column`, `row`.
- `WallRun`: `row`, `startColumn`, `length` (a merged horizontal run).
- `LevelManifestEntry`: `id`, `title`, `par`.
- `ILevelsRepository`: `Future<List<LevelManifestEntry>> getManifest()`, `Future<Level> getLevel(String id)`.
- `LevelFormatException`.

**`level_data`**

- `data_sources/asset_level_data_source/`: reads `levels.json` and level text files through an injected `Future<String> Function(String path)` loader, so the package stays pure Dart. The app passes `rootBundle.loadString`.
- `mappers/`: `LevelTextParser` (text → `Level`, including wall-run merging).
- `repositories/levels_repository.dart`: `LevelsRepository implements ILevelsRepository`, caching parsed levels.

**`level_presentation`**

Two sub-features, each with its own barrel file and Module (the per-screen widget that wires up its dependencies):

- `level_select/`: `LevelSelectModule`, `LevelSelectCubit` (loads manifest plus best times), `LevelSelectView`. Callback: `onLevelSelected(String id)`.
- `level_play/`: `LevelPlayModule`, `LevelPlayCubit`, views, and the renderer. Callbacks: `onNextLevel(String id)`, `onExitToLevels()`.

### Feature: simulation (headless)

**`simulation_domain`**

```dart
abstract interface class IMarbleSimulation {
  void load(Level level);
  void step(Tilt tilt, Duration elapsed);
  void respawn();
  MarbleState get marble;
  Stream<SimulationEvent> get events;
  void dispose();
}
```

- `step` receives wall-clock elapsed time and advances physics on a fixed 1/120 s timestep internally, keeping the remainder for the next call. Elapsed time is clamped to 0.1 s per call so a resume after a stall does not dump a burst of steps.
- `MarbleState`: `position` (`Vector3`), `rotation` (`Quaternion`), `velocity` (`Vector3`), `isActive` (false while sinking or after exit).
- `SimulationEvent` (sealed): `FellInHole(GridPoint hole)`, `LeftBoard()`, `ReachedExit()`, `HitWall(double speed)`. The presentation layer treats `LeftBoard` like a hole fall.
- `Tilt` comes from `tilt_domain`.

**`simulation_data_box3d`**

`Box3dMarbleSimulation implements IMarbleSimulation` using the `box3d` package directly (not `flutter_scene_box3d`), so the simulation is pure Dart and independent of the scene graph.

- One static body holds the floor box, merged wall boxes, and an outer border.
- Holes and exit are sensor spheres on the static body (`isSensor: true`).
- The marble is a dynamic sphere with `isBullet = true` (continuous collision detection). Linear and angular damping approximate rolling resistance.
- Tilt is applied by setting `world.gravity` each step: `gravity = (g·sin(tiltX), -g·cos(tilt), g·sin(tiltY))`. The board never rotates in physics.
- After each step, `drainEvents()` maps sensor-began events to `FellInHole` / `ReachedExit`, and contact-began events above a speed threshold to `HitWall`.
- On `FellInHole` or `ReachedExit` the marble body is made kinematic and frozen (`isActive = false`); the presentation layer plays the animation, then calls `respawn()` or ends the level.
- Safety net: if the marble leaves level bounds, drops below the floor, or has a non-finite position, freeze it and emit `LeftBoard`. Marble speed is clamped each step.

### Feature: tilt (headless)

**`tilt_domain`**

- `Tilt`: `x`, `y` in radians, each clamped to ±`maxTilt` (15°). `Tilt.flat` constant.
- `RawGravity`: `x`, `y`, `z` sensor reading.
- `ITiltRepository`: `Stream<RawGravity> watchGravity()`, `Future<bool> isAvailable()`.
- `TiltFilter` (pure Dart, owns the math): `calibrate(RawGravity)` sets the neutral orientation; `filter(RawGravity) → Tilt` projects onto the screen plane relative to neutral, applies a dead zone (1°), clamps, and low-pass smooths.
- `TouchTiltMapper` (pure Dart): drag offset in logical pixels from touch-down → `Tilt`, with a full-tilt distance of 120 px, clamped. Easing back to flat on release is handled here too, driven by `update(Duration elapsed)`.

**`tilt_data_sensors_plus`**

- `SensorsPlusTiltRepository implements ITiltRepository`, reading `accelerometerEventStream()` from `sensors_plus`.

**Input selection** (in `LevelPlayCubit` / view):

- Accelerometer when `isAvailable()` and at least one event arrives within 500 ms; otherwise touch-only, and a one-time "Drag to tilt" hint is shown.
- While a finger is down, touch overrides the accelerometer, on all devices.

### Feature: progress (headless)

**`progress_domain`**

- `LevelRecord`: `levelId`, `bestTime` (`Duration`).
- `IProgressRepository`: `Future<Map<String, LevelRecord>> getRecords()`, `Future<bool> submitTime(String levelId, Duration time)` (returns whether it was a new best).

**`progress_data_shared_preferences`**

- `SharedPreferencesProgressRepository`, storing best times as milliseconds keyed `best_time.<levelId>`.

### Shared

- `ui_kit`: `ThemeData`, overlay panel, primary/secondary buttons, time formatting (`formatDuration`).
- `localizations`: ARB strings for all UI copy.

### App: marble_maze_app

- Bootstrap: construct `LevelsRepository`, `SensorsPlusTiltRepository`, `SharedPreferencesProgressRepository`; provide them with `RepositoryProvider`.
- Routing: `go_router` + `go_router_builder` typed routes.
  - `LevelSelectRoute` at `/` → `LevelSelectModule`.
  - `LevelPlayRoute` at `/level/:id` → `LevelPlayModule`, constructing a fresh `Box3dMarbleSimulation` per visit.
- Flutter GPU enablement for iOS and Android; portrait lock.
- Unsupported-device screen when Flutter GPU / Impeller is unavailable.

## Level play: runtime

### Frame loop

`LevelPlayView` owns a `Ticker`. Each frame:

1. Compute current `Tilt` from the active input source.
2. `simulation.step(tilt, elapsed)`.
3. Update the scene: board node rotation from `Tilt` (visual only), marble node transform from `simulation.marble`, camera follow.
4. Render the `flutter_scene` `Scene` through a `CustomPainter`.

Simulation events are forwarded to `LevelPlayCubit`. The Cubit never runs per frame.

### LevelPlayCubit states

`LevelPlayLoading` → `LevelPlayReady` → `LevelPlayPlaying` ⇄ `LevelPlayPaused`; `LevelPlayPlaying` → `LevelPlayFalling` → `LevelPlayPlaying`; `LevelPlayPlaying` → `LevelPlayWon` (with time, par, best, `isNewBest`); any → `LevelPlayError`.

The timer is a `Stopwatch` owned by the Cubit, paused while `Paused`. HUD time is read from it on each frame, not emitted as state.

### Rendering (flutter_scene)

- Board: floor box with a wood PBR material; wall boxes per `WallRun`; hole and exit cups as dark cylinders set into the floor. Built-in primitives only, no imported models in v1.
- Marble: sphere with a metallic, low-roughness material.
- Lighting: one directional light with shadows plus image-based lighting from a bundled HDR environment map.
- Camera: fixed pitch of about 55°. Levels that fit on screen are centered; taller levels follow the marble along Z with smoothing.
- Post-processing: tone mapping and bloom.
- Board visual tilt equals the input `Tilt`, applied to the board root node.
- Sink animation: marble translates down and scales to 0 over ~0.5 s. Exit animation: marble settles into the exit cup.

## Error handling

| Failure | Handling |
|---|---|
| Malformed level file | `LevelFormatException` with location; a unit test parses every manifest level, so this fails CI. |
| Level id not in manifest | `LevelPlayError` with a "Back to levels" action. |
| No accelerometer / no events in 500 ms | Fall back to touch; one-time hint. |
| Flutter GPU unavailable | Unsupported-device screen at startup. |
| Marble escapes bounds / NaN state | `LeftBoard` event; handled like a hole fall. |
| Physics instability | Clamp marble speed each step. |
| `shared_preferences` failure | Log, continue without saving; gameplay unaffected. |

## Testing

- **`level_domain` / `level_data`**: parser happy paths, every `LevelFormatException` case, wall-run merging, manifest loading with a fake loader, and a test that parses every bundled level.
- **`tilt_domain`**: calibration, projection, dead zone, clamping, smoothing convergence, touch mapping and release easing.
- **`simulation_domain`**: a reusable contract test suite written against `IMarbleSimulation`, exposed from a `testing/` library in the package:
  - Tilt right → marble moves +X; tilt forward → marble moves −Z.
  - A wall stops the marble.
  - Entering a hole emits `FellInHole`; `respawn()` returns it to start.
  - A marble placed outside the board emits `LeftBoard`.
  - Entering the exit emits `ReachedExit`.
  - A marble at maximum speed never passes through a one-cell wall.
  - Flat tilt → marble at rest stays at rest.
- **`simulation_data_box3d`**: runs the contract suite with `dart test`. Native build hooks compile box3d for the host, so no device is needed. **This is verified in the first implementation task**; if it fails, the fallback is to run these tests via `flutter test` in the same package.
- **`progress_data_shared_preferences`**: round-trip and new-best logic using `SharedPreferences.setMockInitialValues`.
- **`level_presentation`**: `bloc_test` for both Cubits with mocked repositories and a fake simulation; widget tests for HUD, overlays, and level select, with the 3D view behind a seam that tests replace with a placeholder (Flutter GPU does not render in widget tests).
- **Manual, on device**: tilt feel, 60 fps on a mid-range Android phone, visual quality, haptics.

## Risks

| Risk | Mitigation |
|---|---|
| `box3d` is experimental (engine at v0.1). | `IMarbleSimulation` boundary plus the contract suite; a custom engine is a new `simulation_data_custom` package that must pass the same tests. |
| `flutter_scene` is pre-1.0; minor releases may break. | Pin exact versions; isolate rendering to `level_play/views/`. |
| Native build hooks for box3d may complicate iOS/Android builds. | Build both platforms in the first milestone before writing gameplay. |
| Tilt feel is subjective. | All tuning constants (max tilt, dead zone, smoothing, damping, gravity) live in one config object per package. |

## Future work

- Ragdoll cannon game; reconsider `flutter_scene_box3d` (node syncing, joint components) or Rapier (joint limits on ball joints).
- Sound, settings screen, moving hazards, level editor.

## Decisions made during implementation

- **Level id** is the level file's name without its extension (for example `first_roll` for `first_roll.txt`).
- **`levels.json`** lists only level ids, in order. Title and par come from each level file's header, which is the single source of truth; `getManifest()` builds `LevelManifestEntry` values by parsing each file.
- **Contract suite test hook.** The `simulation_domain` `testing/` library takes a factory that returns the simulation plus a backend-supplied `MarbleTestHandle` for placing the marble and setting its velocity. `IMarbleSimulation` itself gets no test-only methods.
- **Tilt sign convention.** Positive `Tilt.x` rolls the marble toward +X (screen right). Positive `Tilt.y` tilts the far edge down and rolls the marble toward −Z (screen up). Touch drag right gives positive `x`; drag up gives positive `y`.
- **`level_domain` models arrive with #3**, so `IMarbleSimulation.load(Level)` has its final shape from the start. #3's arena is a hard-coded `Level`.
- **HDR environment map:** a CC0 map from Poly Haven.
