/// Shared world-space dimensions, so every physics backend's colliders and
/// the level play renderer's visuals agree.
///
/// 1 grid cell = 1 world unit.
library;

/// The marble's collision radius, in world units.
const double kMarbleRadius = 0.3;

/// The height of wall colliders and their matching visual geometry.
const double kWallHeight = 0.6;

/// The radius of a hole's trigger sphere, in world units.
const double kHoleRadius = 0.4;

/// The radius of the exit's trigger sphere, in world units.
const double kExitRadius = 0.35;
