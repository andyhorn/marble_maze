# Bundled assets

## fine_grained_wood_col_1k.jpg

- Source: [Poly Haven — Fine Grained Wood](https://polyhaven.com/a/fine_grained_wood)
- Direct download: https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/fine_grained_wood/fine_grained_wood_col_1k.jpg
- Resolution: 1k
- Licence: [CC0](https://polyhaven.com/license) (public domain, no attribution required)

Used as the base-colour texture for the board's floor and walls
(`BoardSceneView`).

## marble_swirl.png

Generated in-repo, not downloaded: a 512x256 equirectangular three-colour
swirl (cream, amber-brown, deep red-brown), matching `SphereGeometry`'s UV
layout so it wraps the marble without a seam. Used as the marble's
base-colour texture so its rotation as it rolls is visible.

Regenerate with:

```
dart run tool/generate_marble_texture.dart
```

from `features/level/level_presentation/`. See
`tool/generate_marble_texture.dart` for the pattern's construction.
