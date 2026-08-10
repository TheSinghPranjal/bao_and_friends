import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/rewards.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Drink Milk Activity (under Feed) — tap floating milk bubbles (max 4).
/// 1 glass → 1 star. All 4 → 3 stars + 1 Magic Bean. Timer resets 4h.
class DrinkMilkScreen extends StatefulWidget {
  const DrinkMilkScreen({super.key});

  @override
  State<DrinkMilkScreen> createState() => _DrinkMilkScreenState();
}

class _DrinkMilkScreenState extends State<DrinkMilkScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/feed/milk/bao_not_drinking_milk_video.mp4';
  static const _drinkingVideoAsset =
      'assets/videos/feed/milk/bao_drinking_milk_video.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final AnimationController _float;
  late final AnimationController _crossfade;
  final Set<int> _drunk = {};
  bool _celebrating = false;
  bool _sipInProgress = false;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _drinkingVideo;
  bool _idleReady = false;
  bool _drinkingReady = false;
  VoidCallback? _drinkingListener;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _crossfade = AnimationController(
      vsync: this,
      duration: _crossfadeDuration,
    );
    unawaited(_initVideos());
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_idleVideoAsset);
    final drinking = VideoPlayerController.asset(_drinkingVideoAsset);

    try {
      await Future.wait([idle.initialize(), drinking.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await drinking.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await drinking.setLooping(false);
      await drinking.setVolume(0);
      await idle.play();

      _drinkingListener = () {
        final v = _drinkingVideo;
        if (v == null || !_sipInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd = v.value.position >=
            duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishSip());
        }
      };
      drinking.addListener(_drinkingListener!);

      setState(() {
        _idleVideo = idle;
        _drinkingVideo = drinking;
        _idleReady = true;
        _drinkingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await drinking.dispose();
    }
  }

  Future<void> _playSipAnimation() async {
    final drinking = _drinkingVideo;
    if (drinking == null || !_drinkingReady || _sipInProgress) return;

    setState(() => _sipInProgress = true);

    await drinking.seekTo(Duration.zero);
    await drinking.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishSip() async {
    if (!_sipInProgress) return;

    // Keep Bao drinking on screen while the full-reward celebration plays.
    if (_celebrating) {
      final drinking = _drinkingVideo;
      if (drinking != null && drinking.value.isInitialized) {
        await drinking.setLooping(true);
        await drinking.seekTo(Duration.zero);
        await drinking.play();
      }
      return;
    }

    final drinking = _drinkingVideo;
    final idle = _idleVideo;

    drinking?.pause();
    if (idle != null && idle.value.isInitialized && !idle.value.isPlaying) {
      await idle.play();
    }
    if (!mounted) return;

    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _sipInProgress = false);
  }

  @override
  void dispose() {
    final listener = _drinkingListener;
    if (listener != null) {
      _drinkingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _drinkingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble(int index) async {
    if (_celebrating || _drunk.contains(index) || _sipInProgress) return;
    setState(() => _drunk.add(index));
    unawaited(_playSipAnimation());

    if (_drunk.length >= DrinkMilkRules.glassesForFullReward) {
      setState(() => _celebrating = true);
      final reward = DrinkMilkRules.rewardForGlasses(_drunk.length);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _showReward(reward);
      if (!mounted) return;
      context.pop(true);
    }
  }

  Future<void> _showReward(RewardResult reward) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Reward',
      barrierColor: TTColors.darkBrown.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: RewardPopup(
              reward: reward,
              onContinue: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = DrinkMilkRules.maxGlasses - _drunk.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: TTColors.milkCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFBF5),
                  TTColors.milkCream,
                  TTColors.milkSoft,
                ],
              ),
            ),
          ),
          _MilkVideoLayer(
            controller: _idleVideo,
            ready: _idleReady,
          ),
          AnimatedBuilder(
            animation: _crossfade,
            builder: (context, child) {
              return Opacity(
                opacity: Curves.easeInOut.transform(_crossfade.value),
                child: child,
              );
            },
            child: _MilkVideoLayer(
              controller: _drinkingVideo,
              ready: _drinkingReady,
            ),
          ),
          // Soft top wash so status + title stay readable over the video.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TTColors.creamWhite.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28],
                ),
              ),
            ),
          ),
          Column(
            children: [
              TinyStatusBar(
                showCounters: true,
                stars: 12 + (_drunk.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                'Milk with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so creamy!'
                    : 'Tap the milk bubbles ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(DrinkMilkRules.maxGlasses,
                              (i) {
                            final angle = (i / DrinkMilkRules.maxGlasses) *
                                    math.pi *
                                    1.2 -
                                0.3;
                            final bob = math.sin(
                                    (_float.value + i * 0.25) * math.pi * 2) *
                                10;
                            final x = constraints.maxWidth * 0.5 +
                                math.cos(angle) * constraints.maxWidth * 0.32 -
                                (bubbleSize / 2);
                            final y = constraints.maxHeight * 0.12 +
                                math.sin(angle) * 50 +
                                bob;
                            final done = _drunk.contains(i);
                            return Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed: done || _sipInProgress
                                    ? null
                                    : () => _tapBubble(i),
                                enabled: !done && !_sipInProgress,
                                semanticLabel: 'Milk bubble ${i + 1}',
                                child: MilkBubble(
                                  drunk: done,
                                  playing: done && _sipInProgress,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilkVideoLayer extends StatelessWidget {
  const _MilkVideoLayer({
    required this.controller,
    required this.ready,
  });

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    if (!ready || controller == null || !controller!.value.isInitialized) {
      return const SizedBox.expand();
    }

    final size = controller!.value.size;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width > 0 ? size.width : 393,
          height: size.height > 0 ? size.height : 852,
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}

/// Creamy milk bubble — same glassy float language as [WaterGlass].
class MilkBubble extends StatelessWidget {
  const MilkBubble({super.key, required this.drunk, this.playing = false});

  final bool drunk;
  final bool playing;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: playing ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 1.0,
                  colors: drunk
                      ? [
                          Colors.white.withValues(alpha: 0.70),
                          TTColors.milkSoft.withValues(alpha: 0.55),
                          TTColors.milkWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.milkCream.withValues(alpha: 0.45),
                          TTColors.milkSoft.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.milkWarm.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
            Positioned(
              left: _size * 0.18,
              top: _size * 0.16,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: _size * 0.30,
                  height: _size * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              right: _size * 0.20,
              bottom: _size * 0.24,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.80),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Icon(
              drunk ? Icons.local_drink_rounded : Icons.local_drink_outlined,
              size: 32,
              color: drunk
                  ? TTColors.milkWarm.withValues(alpha: 0.95)
                  : TTColors.softBrown,
            ),
            if (drunk)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TTColors.bamboo,
                    border: Border.all(color: TTColors.creamWhite, width: 2),
                    boxShadow: TTShadows.soft,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cute milk reminder (every 4 hours).
class DrinkMilkReminderPopup extends StatelessWidget {
  const DrinkMilkReminderPopup({
    super.key,
    required this.onTap,
    required this.onDismiss,
  });

  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
        boxShadow: TTShadows.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: TTColors.milkSoft,
            ),
            child: const Icon(
              Icons.local_drink_rounded,
              size: 44,
              color: TTColors.softBrown,
            ),
          ),
          const SizedBox(height: 12),
          Text('Time for milk!', style: TTTypography.title()),
          Text(
            'Bao would love some milk with you.',
            textAlign: TextAlign.center,
            style: TTTypography.body(),
          ),
          const SizedBox(height: 16),
          BounceButton(
            onPressed: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 180, minHeight: 56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TTColors.milkWarm,
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
              ),
              child: Text(
                'Let\'s Drink!',
                style: TTTypography.button(color: TTColors.creamWhite),
              ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text('Maybe later', style: TTTypography.caption()),
          ),
        ],
      ),
    );
  }
}
