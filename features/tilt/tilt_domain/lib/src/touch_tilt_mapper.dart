import 'package:tilt_domain/src/tilt.dart';
import 'package:tilt_domain/src/touch_tilt_config.dart';

/// Maps a touch drag, in logical pixels from touch-down, into a [Tilt].
///
/// While a finger is down, call [dragStart] then [dragUpdate] as the finger
/// moves. Call [dragEnd] on release; [update] then eases the tilt back to
/// flat over [TouchTiltConfig.easeDuration].
class TouchTiltMapper {
  /// Creates a touch tilt mapper with the given tuning.
  new({this.config = TouchTiltConfig.standard});

  /// The tuning this mapper uses.
  final TouchTiltConfig config;

  double _startDx = 0;
  double _startDy = 0;
  bool _dragging = false;
  Tilt _tilt = Tilt.flat;
  Tilt _releaseTilt = Tilt.flat;
  Duration _easeElapsed = Duration.zero;

  /// The current tilt.
  Tilt get tilt => _tilt;

  /// Records the touch-down position, in logical pixels.
  void dragStart(double dx, double dy) {
    _dragging = true;
    _startDx = dx;
    _startDy = dy;
  }

  /// Updates the tilt from the current drag position, in logical pixels.
  ///
  /// Screen Y points down, so dragging up (negative [dy] offset) produces a
  /// positive [Tilt.y].
  void dragUpdate(double dx, double dy) {
    if (!_dragging) return;
    final offsetX = dx - _startDx;
    final offsetY = dy - _startDy;
    _tilt = Tilt(
      x: offsetX / config.fullTiltDistance * Tilt.maxTilt,
      y: -offsetY / config.fullTiltDistance * Tilt.maxTilt,
    );
  }

  /// Releases the drag; [update] eases the tilt back to flat from here.
  void dragEnd() {
    _dragging = false;
    _releaseTilt = _tilt;
    _easeElapsed = Duration.zero;
  }

  /// Advances the release easing by [elapsed]. A no-op while dragging or
  /// once flat.
  void update(Duration elapsed) {
    if (_dragging || _tilt == Tilt.flat) return;
    _easeElapsed += elapsed;
    final easeMicros = config.easeDuration.inMicroseconds;
    final t = easeMicros == 0
        ? 1.0
        : (_easeElapsed.inMicroseconds / easeMicros).clamp(0.0, 1.0);
    _tilt = Tilt(
      x: _lerp(_releaseTilt.x, 0, t),
      y: _lerp(_releaseTilt.y, 0, t),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
