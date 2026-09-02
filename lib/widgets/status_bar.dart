import 'dart:async';

import 'package:flutter/material.dart';

import '../services/stars_store.dart';
import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart'; // TTTypography, TTSpacing
import 'back_button_circle.dart';

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

/// Persistent top status bar: Stars + Settings.
///
/// Star count always comes from [StarsStore] so every screen shows the same total.
class TinyStatusBar extends StatelessWidget {
  const TinyStatusBar({
    super.key,
    this.onSettings,
    this.onProfile,
    this.showCounters = true,
    this.leading,
  });

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              const StarCountPill(),
              const SizedBox(width: 10),
            ],
            TtSettingsButton(onPressed: onSettings),
          ],
        ),
      ),
    );
  }
}

/// Cream pill + golden star + shared [StarsStore] count.
class StarCountPill extends StatefulWidget {
  const StarCountPill({super.key});

  /// Same face diameter as back / settings gold circles.
  static const double height = 52;

  @override
  State<StarCountPill> createState() => _StarCountPillState();
}

class _StarCountPillState extends State<StarCountPill> {
  @override
  void initState() {
    super.initState();
    unawaited(StarsStore.total());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StarsStore.totalListenable,
      builder: (context, stars, _) {
        return Container(
          height: StarCountPill.height,
          padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(StarCountPill.height / 2),
            boxShadow: [
              BoxShadow(
                color: TTColors.darkBrown.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE066),
                    Color(0xFFFFC93C),
                    Color(0xFFF5A623),
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$stars',
                style:
                    TTTypography.title(color: const Color(0xFF5A5A5A)).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
