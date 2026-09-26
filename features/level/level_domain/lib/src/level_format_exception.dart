/// A level file failed to parse.
///
/// Carries [file], [line], and [column] so the failure can be pinpointed in
/// the offending asset, plus a human-readable [reason].
class LevelFormatException implements Exception {
  /// Creates a level format exception.
  const new({
    required this.file,
    required this.line,
    required this.column,
    required this.reason,
  });

  /// The level file's path.
  final String file;

  /// The 1-based line the error occurred on.
  final int line;

  /// The 1-based column the error occurred at.
  final int column;

  /// A human-readable description of the failure.
  final String reason;

  @override
  String toString() => '$file:$line:$column: $reason';
}
