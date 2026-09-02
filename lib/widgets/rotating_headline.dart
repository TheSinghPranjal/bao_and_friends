import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart';

/// Thick headline that cycles phrases every [interval] with a smooth fade/slide.
class RotatingHeadline extends StatefulWidget {
  const RotatingHeadline({
    super.key,
    required this.phrases,
    this.interval = const Duration(seconds: 10),
    this.color,
  });

  /// Short prompts (aim for ≤3 words each).
  final List<String> phrases;
  final Duration interval;
  final Color? color;

  @override
  State<RotatingHeadline> createState() => _RotatingHeadlineState();
}

class _RotatingHeadlineState extends State<RotatingHeadline> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RotatingHeadline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.phrases.length != widget.phrases.length) {
      _timer?.cancel();
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    if (widget.phrases.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.phrases.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases.isEmpty
        ? ''
        : widget.phrases[_index % widget.phrases.length];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: Text(
        phrase,
        key: ValueKey<String>(phrase),
        textAlign: TextAlign.center,
        style: TTTypography.headline(color: widget.color ?? TTColors.darkBrown)
            .copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 30,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Default rotating prompts for Learn (and similar hubs).
abstract final class LearnHeadlinePhrases {
  static const all = <String>[
    'Learn with Bao!',
    'Play with Bao',
    'Feed Bao',
    'Lets play football',
    'Lets learn',
    'Drink with Bao',
    'Time for chores',
    'Wake up Bao',
    'Wear your shoes',
    'Make the bed',
  ];
}
