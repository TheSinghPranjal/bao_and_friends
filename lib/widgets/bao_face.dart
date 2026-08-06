import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';

/// Bao's face — locked Mickey-level consistency.
/// Proportions must not change across screens.
class BaoFace extends StatelessWidget {
  const BaoFace({
    super.key,
    this.size = 72,
    this.showCollar = true,
    this.expression = BaoExpression.smile,
  });

  final double size;
  final bool showCollar;
  final BaoExpression expression;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BaoFacePainter(
          showCollar: showCollar,
          expression: expression,
        ),
      ),
    );
  }
}

enum BaoExpression { smile, blink, wave }

class _BaoFacePainter extends CustomPainter {
  _BaoFacePainter({required this.showCollar, required this.expression});

  final bool showCollar;
  final BaoExpression expression;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Head (white)
    final headPaint = Paint()..color = TTColors.baoFurWhite;
    canvas.drawCircle(Offset(cx, cy), r * 0.92, headPaint);

    // Soft outline
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.92,
      Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02,
    );

    // Ears
    final earPaint = Paint()..color = TTColors.baoFurBlack;
    canvas.drawCircle(
      Offset(cx - r * 0.62, cy - r * 0.58),
      r * 0.28,
      earPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.62, cy - r * 0.58),
      r * 0.28,
      earPaint,
    );

    // Eye patches (signature black markings)
    final patchPaint = Paint()..color = TTColors.baoFurBlack;
    final leftPatch = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - r * 0.32, cy - r * 0.05),
        width: r * 0.52,
        height: r * 0.58,
      ),
      Radius.circular(r * 0.28),
    );
    final rightPatch = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + r * 0.32, cy - r * 0.05),
        width: r * 0.52,
        height: r * 0.58,
      ),
      Radius.circular(r * 0.28),
    );
    canvas.drawRRect(leftPatch, patchPaint);
    canvas.drawRRect(rightPatch, patchPaint);

    // Eyes
    final eyeWhite = Paint()..color = TTColors.baoEyeWhite;
    final iris = Paint()..color = TTColors.baoIris;
    final leftEye = Offset(cx - r * 0.32, cy - r * 0.02);
    final rightEye = Offset(cx + r * 0.32, cy - r * 0.02);

    if (expression == BaoExpression.blink) {
      final lid = Paint()
        ..color = TTColors.baoFurWhite
        ..strokeWidth = size.width * 0.04
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        leftEye.translate(-r * 0.12, 0),
        leftEye.translate(r * 0.12, 0),
        lid,
      );
      canvas.drawLine(
        rightEye.translate(-r * 0.12, 0),
        rightEye.translate(r * 0.12, 0),
        lid,
      );
    } else {
      canvas.drawCircle(leftEye, r * 0.16, eyeWhite);
      canvas.drawCircle(rightEye, r * 0.16, eyeWhite);
      canvas.drawCircle(leftEye.translate(r * 0.02, r * 0.02), r * 0.09, iris);
      canvas.drawCircle(rightEye.translate(r * 0.02, r * 0.02), r * 0.09, iris);
      // Highlights
      final hi = Paint()..color = Colors.white;
      canvas.drawCircle(leftEye.translate(-r * 0.04, -r * 0.04), r * 0.035, hi);
      canvas.drawCircle(rightEye.translate(-r * 0.04, -r * 0.04), r * 0.035, hi);
    }

    // Nose
    final nose = Paint()..color = TTColors.baoFurBlack;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.22),
        width: r * 0.18,
        height: r * 0.12,
      ),
      nose,
    );

    // Smile
    final smile = Paint()
      ..color = TTColors.baoFurBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(cx - r * 0.16, cy + r * 0.38)
      ..quadraticBezierTo(cx, cy + r * 0.52, cx + r * 0.16, cy + r * 0.38);
    canvas.drawPath(smilePath, smile);

    // Blue collar
    if (showCollar) {
      final collar = Paint()..color = TTColors.baoCollar;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy + r * 0.55), radius: r * 0.55),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        collar
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BaoFacePainter oldDelegate) =>
      oldDelegate.expression != expression ||
      oldDelegate.showCollar != showCollar;
}

/// Soft pulsing glow ring around Bao's face (splash logo heartbeat).
class BaoGlowRing extends StatefulWidget {
  const BaoGlowRing({
    super.key,
    required this.child,
    this.size = 72,
  });

  final Widget child;
  final double size;

  @override
  State<BaoGlowRing> createState() => _BaoGlowRingState();
}

class _BaoGlowRingState extends State<BaoGlowRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: widget.size + 16,
          height: widget.size + 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TTColors.goldenGlow.withValues(
                  alpha: 0.35 + (_pulse.value - 0.85) * 0.5,
                ),
                blurRadius: 12 * _pulse.value,
                spreadRadius: 2 * _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
