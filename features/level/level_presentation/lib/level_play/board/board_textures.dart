import 'dart:async';

import 'package:flutter_scene/scene.dart';

/// The oak textures used for the floor and walls: base colour, OpenGL
/// convention normal map, and a greyscale roughness map (read from its green
/// channel, as glTF's metallic-roughness slot expects). See
/// `assets/textures/ASSETS.md` for their source and licence.
const _woodColorAsset =
    'packages/level_presentation/assets/textures/oak_veneer_01_diff_2k.jpg';
const _woodNormalAsset =
    'packages/level_presentation/assets/textures/oak_veneer_01_nor_gl_2k.jpg';
const _woodRoughnessAsset =
    'packages/level_presentation/assets/textures/oak_veneer_01_rough_1k.jpg';

/// The generated marble base-colour swirl texture. See
/// `assets/textures/ASSETS.md` for how it's built.
const _marbleTextureAsset =
    'packages/level_presentation/assets/textures/marble_swirl.png';

/// The textures every board and marble samples, decoded and uploaded to the
/// GPU once and shared by every level rather than reloaded on each entry.
class BoardTextures {
  const new _({
    required this.woodColor,
    required this.woodNormal,
    required this.woodRoughness,
    required this.marble,
  });

  /// The wood base-colour texture.
  final Texture2D woodColor;

  /// The wood normal map.
  final Texture2D woodNormal;

  /// The wood roughness map, read from its green channel.
  final Texture2D woodRoughness;

  /// The marble's swirl base-colour texture.
  final Texture2D marble;

  static Future<BoardTextures>? _pending;

  /// Loads the textures on first use and returns the same instance
  /// afterwards; concurrent callers share one in-flight load.
  ///
  /// Requires `Scene.initializeStaticResources` to have completed. A failed
  /// load is not cached, so a later call retries.
  static Future<BoardTextures> load() {
    final pending = _pending ??= _loadTextures();
    unawaited(
      pending.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_pending, pending)) _pending = null;
        },
      ),
    );
    return pending;
  }

  /// Starts [load] without waiting for it, so the textures are ready by the
  /// time a level asks for them. A failure here is swallowed: the level
  /// that needs the textures calls [load] itself and surfaces any error.
  static void preload() =>
      unawaited(load().then<void>((_) {}, onError: (_) {}));

  static Future<BoardTextures> _loadTextures() async {
    final woodColor = await Texture2D.fromAsset(_woodColorAsset);
    final woodNormal = await Texture2D.fromAsset(
      _woodNormalAsset,
      content: TextureContent.normal,
    );
    final woodRoughness = await Texture2D.fromAsset(
      _woodRoughnessAsset,
      content: TextureContent.data,
    );
    final marble = await Texture2D.fromAsset(_marbleTextureAsset);
    return BoardTextures._(
      woodColor: woodColor,
      woodNormal: woodNormal,
      woodRoughness: woodRoughness,
      marble: marble,
    );
  }
}
