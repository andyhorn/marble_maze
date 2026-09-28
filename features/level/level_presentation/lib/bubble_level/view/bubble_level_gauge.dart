import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The bubble level's circular vial: crosshair, target ring and a bubble
/// that floats toward the high side of the device.
class BubbleLevelGauge extends StatelessWidget {
  /// Creates a gauge for a device tilted by [xAngle] and [yAngle] radians.
  const new({required this.xAngle, required this.yAngle, super.key});

  /// The tilt about the screen's vertical axis; positive is right edge up.
  final double xAngle;

  /// The tilt about the screen's horizontal axis; positive is top edge up.
  final double yAngle;

  /// The tilt, in radians, at which the bubble reaches the vial's edge
  /// (15 degrees).
  static const double fullScaleAngle = 15 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _GaugePainter(
          xAngle: xAngle,
          yAngle: yAngle,
          vialColor: colors.surfaceContainerHighest,
          lineColor: colors.outline,
          bubbleColor: colors.primary,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  new({
    required this.xAngle,
    required this.yAngle,
    required this.vialColor,
    required this.lineColor,
    required this.bubbleColor,
  });

  final double xAngle;
  final double yAngle;
  final Color vialColor;
  final Color lineColor;
  final Color bubbleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final vialRadius = size.shortestSide / 2;
    final bubbleRadius = vialRadius * 0.14;
    final travel = vialRadius - bubbleRadius;

    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas
      ..drawCircle(center, vialRadius, Paint()..color = vialColor)
      ..drawCircle(center, vialRadius, line)
      ..drawCircle(center, bubbleRadius * 1.5, line)
      ..drawLine(
        center.translate(-vialRadius, 0),
        center.translate(vialRadius, 0),
        line,
      )
      ..drawLine(
        center.translate(0, -vialRadius),
        center.translate(0, vialRadius),
        line,
      );

    final raw = Offset(
      xAngle / BubbleLevelGauge.fullScaleAngle,
      -yAngle / BubbleLevelGauge.fullScaleAngle,
    );
    final distance = math.min(raw.distance, 1);
    final direction = raw.distance == 0 ? Offset.zero : raw / raw.distance;
    final bubbleCenter = center + direction * (distance * travel);

    canvas.drawCircle(
      bubbleCenter,
      bubbleRadius,
      Paint()..color = bubbleColor.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.xAngle != xAngle ||
      oldDelegate.yAngle != yAngle ||
      oldDelegate.vialColor != vialColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.bubbleColor != bubbleColor;
}
