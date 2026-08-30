import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';

/// Soft circular countdown ring around a child icon (home activity sheet).
class CircularTimerRing extends StatelessWidget {
  const CircularTimerRing({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.isDue = false,
    this.size = 44,
    this.strokeWidth = 3.2,
  });

  /// 1 = full (plenty of time); 0 = empty / due.
  final double progress;
  final Color color;
  final Widget child;
  final bool isDue;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ringColor = isDue ? TTColors.ribbonOrange : color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: isDue ? 0.08 : progress.clamp(0.0, 1.0),
              color: ringColor,
              trackColor: TTColors.darkBrown.withValues(alpha: 0.12),
              strokeWidth: strokeWidth,
              pulse: isDue,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.pulse,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.pulse != pulse;
  }
}
