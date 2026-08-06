import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart'; // TTTypography, TTSpacing

/// Organic bamboo-leaf loader — fills left→right, never shows %.
class BambooLeafLoader extends StatefulWidget {
  const BambooLeafLoader({
    super.key,
    this.leafCount = 5,
    this.duration = const Duration(milliseconds: 2800),
  });

  final int leafCount;
  final Duration duration;

  @override
  State<BambooLeafLoader> createState() => _BambooLeafLoaderState();
}

class _BambooLeafLoaderState extends State<BambooLeafLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.leafCount, (i) {
            final threshold = (i + 1) / widget.leafCount;
            final filled = progress >= threshold - 0.12;
            final local = ((progress - (i / widget.leafCount)) *
                    widget.leafCount)
                .clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, filled ? -2.0 * local : 0),
                child: Opacity(
                  opacity: 0.35 + (filled ? 0.65 * local : 0),
                  child: CustomPaint(
                    size: const Size(22, 28),
                    painter: _LeafPainter(
                      color: Color.lerp(
                        TTColors.bambooLight,
                        TTColors.bamboo,
                        local,
                      )!,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
        size.width * 1.1,
        size.height * 0.45,
        size.width * 0.5,
        size.height,
      )
      ..quadraticBezierTo(
        size.width * -0.1,
        size.height * 0.45,
        size.width * 0.5,
        0,
      );
    canvas.drawPath(path, Paint()..color = color);
    // Vein
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.12),
      Offset(size.width * 0.5, size.height * 0.88),
      Paint()
        ..color = TTColors.bambooDeep.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Persistent top status bar: Stars, Beans, Level, Settings.
class TinyStatusBar extends StatelessWidget {
  const TinyStatusBar({
    super.key,
    this.stars = 0,
    this.beans = 0,
    this.level = 1,
    this.onSettings,
    this.onProfile,
    this.showCounters = true,
    this.leading,
  });

  final int stars;
  final int beans;
  final int level;
  final VoidCallback? onSettings;
  final VoidCallback? onProfile;
  final bool showCounters;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            leading ??
                GestureDetector(
                  onTap: onProfile,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TTColors.creamWhite,
                      border: Border.all(color: TTColors.skyBlue, width: 2),
                      boxShadow: TTShadows.soft,
                    ),
                    child: const Icon(Icons.pets, color: TTColors.skyDeep),
                  ),
                ),
            const Spacer(),
            if (showCounters) ...[
              _Chip(
                icon: Icons.star_rounded,
                iconColor: TTColors.golden,
                value: '$stars',
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.eco_rounded,
                iconColor: TTColors.bamboo,
                value: '$beans',
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.emoji_events_rounded,
                iconColor: TTColors.ribbonOrange,
                value: 'Lv $level',
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onSettings,
              child: Container(
                width: TTSpacing.touchMin,
                height: TTSpacing.touchMin,
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: TTColors.creamWhite,
                    shape: BoxShape.circle,
                    boxShadow: TTShadows.soft,
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: TTColors.softBrown,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TTColors.creamWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
        boxShadow: TTShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(value, style: TTTypography.subtitle(color: TTColors.darkBrown)),
        ],
      ),
    );
  }
}
