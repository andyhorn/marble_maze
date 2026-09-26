/// Formats [duration] as a race-clock time, for example `1:05.32`, or
/// `1:02:03.40` once an hour has elapsed.
String formatDuration(Duration duration) {
  final totalMilliseconds = duration.inMilliseconds.abs();
  final hours = totalMilliseconds ~/ Duration.millisecondsPerHour;
  final minutes =
      (totalMilliseconds % Duration.millisecondsPerHour) ~/
      Duration.millisecondsPerMinute;
  final seconds =
      (totalMilliseconds % Duration.millisecondsPerMinute) ~/
      Duration.millisecondsPerSecond;
  final centiseconds =
      (totalMilliseconds % Duration.millisecondsPerSecond) ~/ 10;

  final secondsPart =
      '${seconds.toString().padLeft(2, '0')}.'
      '${centiseconds.toString().padLeft(2, '0')}';
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$secondsPart';
  }
  return '$minutes:$secondsPart';
}
