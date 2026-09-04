import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/rewards.dart';
import '../../services/schedule_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Drink Water Activity — tap floating glasses (max 4).
/// 1 glass → 1 star. All 4 → 3 stars + 1 Magic Bean. Timer resets 4h.
class DrinkWaterScreen extends StatefulWidget {
  const DrinkWaterScreen({super.key});

  @override
  State<DrinkWaterScreen> createState() => _DrinkWaterScreenState();
}

class _DrinkWaterScreenState extends State<DrinkWaterScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/feed/water/bao_not_drinking_water.mp4';
  static const _drinkingVideoAsset =
      'assets/videos/feed/water/bao_drinking_water.mp4';
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

  Future<void> _tapGlass(int index) async {
    if (_celebrating || _drunk.contains(index) || _sipInProgress) return;
    setState(() => _drunk.add(index));
    unawaited(_playSipAnimation());

    if (_drunk.length >= DrinkWaterRules.glassesForFullReward) {
      setState(() => _celebrating = true);
      final reward = DrinkWaterRules.rewardForGlasses(_drunk.length);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await StarsStore.add(reward.stars);
      await _showReward(reward);
      if (!mounted) return;
      await ScheduleStore.markCompleted(ActivityId.drink);
      if (!mounted) return;
      context.pop();
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
    // Bubble is 84x84 now (was 80x100) — keep centering offsets in sync
    // with WaterGlass's outer size below.
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB8E8F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB8E8F8),
                  TTColors.waterBlue,
                  Color(0xFF6EC6E8),
                ],
              ),
            ),
          ),
          _DrinkVideoLayer(
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
            child: _DrinkVideoLayer(
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
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Text(
                'Sip with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(DrinkWaterRules.maxGlasses,
                                  (i) {
                                final angle = (i / DrinkWaterRules.maxGlasses) *
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
                                        : () => _tapGlass(i),
                                    enabled: !done && !_sipInProgress,
                                    semanticLabel: 'Water glass ${i + 1}',
                                    child: WaterGlass(
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

class _DrinkVideoLayer extends StatelessWidget {
  const _DrinkVideoLayer({
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

/// Transparent, glassy water bubble — replaces the old square glass card.
/// Shows a soft radial-gradient sphere with a glare highlight and a
/// water-drop glyph inside, matching the floating bubble reference art.
class WaterGlass extends StatelessWidget {
  const WaterGlass({super.key, required this.drunk, this.playing = false});

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
            // Outer glassy sphere.
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
                    Colors.white.withValues(alpha: 0.55),
                    TTColors.waterBlue.withValues(alpha: 0.30),
                    TTColors.waterBlue.withValues(alpha: 0.50),
                  ]
                      : [
                    Colors.white.withValues(alpha: 0.80),
                    TTColors.waterBlue.withValues(alpha: 0.18),
                    TTColors.waterBlue.withValues(alpha: 0.32),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.waterBlue.withValues(alpha: 0.28),
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
            // Glare highlight, top-left, like the bubble reference art.
            Positioned(
              left: _size * 0.18,
              top: _size * 0.16,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: _size * 0.30,
                  height: _size * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            // Small secondary sparkle.
            Positioned(
              right: _size * 0.20,
              bottom: _size * 0.24,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Water drop glyph centered inside the bubble.
            Icon(
              drunk ? Icons.water_drop_rounded : Icons.water_drop_outlined,
              size: 32,
              color: drunk
                  ? TTColors.waterBlue.withValues(alpha: 0.95)
                  : TTColors.waterDrop,
            ),
            // Completed check badge.
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

class RewardPopup extends StatelessWidget {
  const RewardPopup({
    super.key,
    required this.reward,
    required this.onContinue,
  });

  final RewardResult reward;
  final VoidCallback onContinue;

  static const _cardCream = Color(0xFFFFF8F0);
  static const _cardBorder = Color(0xFFE8D5B5);
  static const _titleBrown = Color(0xFF4E342E);
  static const _bodyBrown = Color(0xFF6D4C41);
  static const _captionBrown = Color(0xFFA1887F);
  static const _starPillFill = Color(0xFFFFF3C4);
  static const _starPillBorder = Color(0xFFE8B820);
  static const _btnTop = Color(0xFFFFE066);
  static const _btnBottom = Color(0xFFF5C542);
  static const _btnShadow = Color(0xFFE0A800);

  @override
  Widget build(BuildContext context) {
    final stars = reward.stars > 0 ? reward.stars : 1;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 320,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Card
            Container(
              width: 320,
              margin: const EdgeInsets.only(top: 72),
              padding: const EdgeInsets.fromLTRB(22, 78, 22, 22),
              decoration: BoxDecoration(
                color: _cardCream,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: _cardBorder, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confetti / sparkles
                  ..._confettiDots(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Wonderful!',
                        style: TTTypography.headline(color: _titleBrown)
                            .copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reward.message,
                        textAlign: TextAlign.center,
                        style: TTTypography.body(color: _bodyBrown).copyWith(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Stars reward pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _starPillFill,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _starPillBorder,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _starPillBorder.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 40,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+$stars',
                              style: TTTypography.title(color: _titleBrown)
                                  .copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Stars burst – you shine bright!',
                        textAlign: TextAlign.center,
                        style: TTTypography.caption(color: _captionBrown)
                            .copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 3D Yay button
                      BounceButton(
                        onPressed: onContinue,
                        semanticLabel: 'Yay',
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 58),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_btnTop, _btnBottom],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: _btnShadow,
                                offset: Offset(0, 6),
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Color(0x55C48A00),
                                offset: Offset(0, 10),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Text(
                            'Yay!',
                            style: TTTypography.button(color: _titleBrown)
                                .copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bao + glow sitting on top of the card
            Positioned(
              top: 0,
              child: SizedBox(
                width: 200,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft golden glow / sunburst
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFF59D).withValues(alpha: 0.95),
                            const Color(0xFFFFE082).withValues(alpha: 0.55),
                            const Color(0xFFFFE082).withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    // Tiny floating stars around Bao
                    const Positioned(
                      left: 8,
                      top: 28,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD54F),
                        size: 18,
                      ),
                    ),
                    const Positioned(
                      right: 10,
                      top: 18,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 22,
                      ),
                    ),
                    const Positioned(
                      right: 28,
                      top: 52,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFE082),
                        size: 14,
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      top: 56,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFCA28),
                        size: 12,
                      ),
                    ),
                    // Bao character
                    Image.asset(
                      'assets/images/bao_reward_celebrate.png',
                      width: 168,
                      height: 140,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _confettiDots() {
    const pieces = <(double, double, Color, double)>[
      (12, 18, Color(0xFFF48FB1), 7),
      (48, 8, Color(0xFF90CAF9), 6),
      (270, 22, Color(0xFFFFF176), 7),
      (250, 70, Color(0xFFF48FB1), 5),
      (20, 110, Color(0xFF80DEEA), 6),
      (275, 130, Color(0xFFFFCC80), 6),
      (40, 200, Color(0xFFCE93D8), 5),
      (260, 195, Color(0xFF90CAF9), 5),
    ];
    return [
      for (final p in pieces)
        Positioned(
          left: p.$1,
          top: p.$2,
          child: Transform.rotate(
            angle: (p.$1 + p.$2) % 40 / 20,
            child: Container(
              width: p.$4,
              height: p.$4 * 0.55,
              decoration: BoxDecoration(
                color: p.$3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      const Positioned(
        left: 30,
        top: 55,
        child: Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 12),
      ),
      const Positioned(
        right: 36,
        top: 48,
        child: Icon(Icons.star_rounded, color: Color(0xFFFFCA28), size: 10),
      ),
      const Positioned(
        left: 55,
        bottom: 90,
        child: Icon(Icons.star_rounded, color: Color(0xFFFFE082), size: 11),
      ),
    ];
  }
}

/// Cute water-drop reminder (every 4 hours).
class DrinkWaterReminderPopup extends StatelessWidget {
  const DrinkWaterReminderPopup({
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
              color: TTColors.waterBlue,
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 44,
              color: TTColors.creamWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text('Time for a sip!', style: TTTypography.title()),
          Text(
            'Bao would love some water with you.',
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
                color: TTColors.waterDrop,
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