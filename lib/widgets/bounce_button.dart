import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart';

/// Squash-and-stretch tap feedback for toddler buttons.
class BounceButton extends StatefulWidget {
  const BounceButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    await _controller.forward(from: 0);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Large golden Play CTA with breathing pulse.
class PlayCtaButton extends StatefulWidget {
  const PlayCtaButton({
    super.key,
    required this.onPressed,
    this.label = 'Play',
    this.comingSoon = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool comingSoon;

  @override
  State<PlayCtaButton> createState() => _PlayCtaButtonState();
}

class _PlayCtaButtonState extends State<PlayCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comingSoon) {
      return Container(
        constraints: const BoxConstraints(
          minWidth: TTSpacing.playButtonMinW,
          minHeight: TTSpacing.playButtonMinH,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: TTColors.creamWhite.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
          border: Border.all(color: TTColors.ribbonOrange, width: 2),
          boxShadow: TTShadows.soft,
        ),
        alignment: Alignment.center,
        child: Text(
          'Coming Soon',
          style: TTTypography.button(color: TTColors.ribbonOrange),
        ),
      );
    }

    return BounceButton(
      onPressed: widget.onPressed,
      semanticLabel: widget.label,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Transform.scale(
            scale: 1.0 + t * 0.04,
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: TTSpacing.playButtonMinW,
            minHeight: TTSpacing.playButtonMinH,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TTColors.goldenBright, TTColors.golden],
            ),
            borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
            boxShadow: [
              ...TTShadows.soft,
              ...TTShadows.glow(TTColors.goldenGlow),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets_rounded, color: TTColors.darkBrown, size: 28),
              const SizedBox(width: 10),
              Text(widget.label, style: TTTypography.button()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded placeholder for looping video / idle animation assets.
class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({
    super.key,
    required this.label,
    this.width,
    this.height = 160,
    this.child,
  });

  final String label;
  final double? width;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TTColors.skySoft.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(TTSpacing.radiusLg),
        border: Border.all(color: TTColors.creamWhite, width: 3),
        boxShadow: TTShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?child,
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  TTColors.darkBrown.withValues(alpha: 0.45),
                ],
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TTTypography.caption(color: TTColors.creamWhite),
            ),
          ),
        ],
      ),
    );
  }
}
