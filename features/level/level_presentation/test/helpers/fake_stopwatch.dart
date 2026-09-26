/// A [Stopwatch] double with a settable [elapsed], so tests can assert on a
/// level play cubit's reported time without waiting on the real clock.
class FakeStopwatch implements Stopwatch {
  /// The elapsed time this stopwatch reports, settable directly by tests.
  @override
  Duration elapsed = Duration.zero;

  @override
  bool isRunning = false;

  @override
  void start() => isRunning = true;

  @override
  void stop() => isRunning = false;

  @override
  void reset() => elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMicroseconds;

  @override
  int get frequency => 1000000;
}
