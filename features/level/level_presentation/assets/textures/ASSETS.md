# Bundled assets

## oak_veneer_01_*.jpg

- Source: [Poly Haven — Oak Veneer 01](https://polyhaven.com/a/oak_veneer_01)
- Downloads (2k JPG): `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/oak_veneer_01/oak_veneer_01_{diff,nor_gl,rough}_2k.jpg`
- Licence: [CC0](https://polyhaven.com/license) (public domain, no attribution required)

Used for the board's floor and walls (`BoardSceneView`):

- `oak_veneer_01_diff_2k.jpg`: base colour, re-encoded at JPEG quality 85.
- `oak_veneer_01_nor_gl_2k.jpg`: OpenGL-convention normal map, re-encoded
  at quality 90.
- `oak_veneer_01_rough_1k.jpg`: roughness, converted to greyscale and
  downsized to 1k (quality 85). The material reads it through glTF's
  metallic-roughness slot, which takes roughness from the green channel.

Re-encode with ImageMagick:

```
magick oak_veneer_01_diff_2k.jpg -strip -quality 85 oak_veneer_01_diff_2k.jpg
magick oak_veneer_01_nor_gl_2k.jpg -strip -quality 90 oak_veneer_01_nor_gl_2k.jpg
magick oak_veneer_01_rough_2k.jpg -strip -colorspace Gray -resize 1024x1024 -quality 85 oak_veneer_01_rough_1k.jpg
```

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
