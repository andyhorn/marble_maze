/// Tracks per-frame deltas for the board's ticker, clamping a stalled
/// frame's delta and pausing its own accumulated clock while inactive.
///
/// Kept as a pure class, separate from the ticker that drives it, so a
/// unit test can exercise clamping and pausing without a real frame loop.
/// A stall happens, for example, while the app is backgrounded: no frames
/// are scheduled, so the next tick's timestamp jumps by the whole gap.
class FrameClock {
  /// Creates a frame clock that clamps each tick's delta to [maxDelta].
  new({this.maxDelta = const Duration(milliseconds: 33)});

  /// The largest delta [tick] returns for a single frame.
  final Duration maxDelta;

  Duration _lastTimestamp = Duration.zero;
  Duration _activeElapsed = Duration.zero;
  Duration _totalElapsed = Duration.zero;

  /// The accumulated duration across every [tick] called with
  /// `isActive: true`, unaffected by ticks while inactive.
  Duration get activeElapsed => _activeElapsed;

  /// The accumulated duration across every [tick], active or not, with
  /// each frame's delta clamped to [maxDelta].
  Duration get totalElapsed => _totalElapsed;

  /// Advances the clock to [timestamp] (a ticker's cumulative elapsed time)
  /// and returns this frame's delta, clamped to [maxDelta]. If [isActive],
  /// the clamped delta is also added to [activeElapsed].
  Duration tick(Duration timestamp, {required bool isActive}) {
    final raw = timestamp - _lastTimestamp;
    _lastTimestamp = timestamp;
    final delta = raw.isNegative
        ? Duration.zero
        : (raw > maxDelta ? maxDelta : raw);
    _totalElapsed += delta;
    if (isActive) _activeElapsed += delta;
    return delta;
  }
}
