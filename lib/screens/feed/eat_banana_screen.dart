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

/// Eat Banana Activity (under Feed) — tap floating banana bubbles (max 4).
/// 1 banana → 1 star. All 4 → 3 stars + 1 Magic Bean. Timer resets 4h.
class EatBananaScreen extends StatefulWidget {
  const EatBananaScreen({super.key});

  @override
  State<EatBananaScreen> createState() => _EatBananaScreenState();
}

class _EatBananaScreenState extends State<EatBananaScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/feed/banana/bao_not_eating_banana.mp4';
  static const _eatingVideoAsset =
      'assets/videos/feed/banana/bao_eating_banana.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final AnimationController _float;
  late final AnimationController _crossfade;
  final Set<int> _eaten = {};
  bool _celebrating = false;
  bool _biteInProgress = false;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _eatingVideo;
  bool _idleReady = false;
  bool _eatingReady = false;
  VoidCallback? _eatingListener;

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
    final eating = VideoPlayerController.asset(_eatingVideoAsset);

    try {
      await Future.wait([idle.initialize(), eating.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await eating.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await eating.setLooping(false);
      await eating.setVolume(0);
      await idle.play();

      _eatingListener = () {
        final v = _eatingVideo;
        if (v == null || !_biteInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd = v.value.position >=
            duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishBite());
        }
      };
      eating.addListener(_eatingListener!);

      setState(() {
        _idleVideo = idle;
        _eatingVideo = eating;
        _idleReady = true;
        _eatingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await eating.dispose();
    }
  }

  Future<void> _playBiteAnimation() async {
    final eating = _eatingVideo;
    if (eating == null || !_eatingReady || _biteInProgress) return;

    setState(() => _biteInProgress = true);

    await eating.seekTo(Duration.zero);
    await eating.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishBite() async {
    if (!_biteInProgress) return;

    // Keep Bao eating on screen while the full-reward celebration plays.
    if (_celebrating) {
      final eating = _eatingVideo;
      if (eating != null && eating.value.isInitialized) {
        await eating.setLooping(true);
        await eating.seekTo(Duration.zero);
        await eating.play();
      }
      return;
    }

    final eating = _eatingVideo;
    final idle = _idleVideo;

    eating?.pause();
    if (idle != null && idle.value.isInitialized && !idle.value.isPlaying) {
      await idle.play();
    }
    if (!mounted) return;

    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _biteInProgress = false);
  }

  @override
  void dispose() {
    final listener = _eatingListener;
    if (listener != null) {
      _eatingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _eatingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble(int index) async {
    if (_celebrating || _eaten.contains(index) || _biteInProgress) return;
    setState(() => _eaten.add(index));
    unawaited(_playBiteAnimation());

    if (_eaten.length >= EatBananaRules.bananasForFullReward) {
      setState(() => _celebrating = true);
      final reward = EatBananaRules.rewardForBananas(_eaten.length);
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
    final remaining = EatBananaRules.maxBananas - _eaten.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: TTColors.bananaCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFDE7),
                  TTColors.bananaCream,
                  TTColors.bananaSoft,
                ],
              ),
            ),
          ),
          _BananaVideoLayer(
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
            child: _BananaVideoLayer(
              controller: _eatingVideo,
              ready: _eatingReady,
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
                stars: 12 + (_eaten.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                'Banana with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so yummy!'
                    : 'Tap the banana bubbles ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(EatBananaRules.maxBananas,
                              (i) {
                            final angle = (i / EatBananaRules.maxBananas) *
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
                            final done = _eaten.contains(i);
                            return Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed: done || _biteInProgress
                                    ? null
                                    : () => _tapBubble(i),
                                enabled: !done && !_biteInProgress,
                                semanticLabel: 'Banana bubble ${i + 1}',
                                child: BananaBubble(
                                  eaten: done,
                                  playing: done && _biteInProgress,
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

class _BananaVideoLayer extends StatelessWidget {
  const _BananaVideoLayer({
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

/// Sunny banana bubble — same glassy float language as [AppleBubble].
class BananaBubble extends StatelessWidget {
  const BananaBubble({super.key, required this.eaten, this.playing = false});

  final bool eaten;
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
                  colors: eaten
                      ? [
                          Colors.white.withValues(alpha: 0.70),
                          TTColors.bananaSoft.withValues(alpha: 0.55),
                          TTColors.bananaWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.bananaCream.withValues(alpha: 0.45),
                          TTColors.bananaSoft.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.bananaWarm.withValues(alpha: 0.28),
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
              Icons.breakfast_dining_rounded,
              size: 34,
              color: eaten
                  ? TTColors.bananaWarm.withValues(alpha: 0.95)
                  : TTColors.bananaDeep,
            ),
            if (eaten)
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

/// Cute banana reminder (every 4 hours).
class EatBananaReminderPopup extends StatelessWidget {
  const EatBananaReminderPopup({
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
              color: TTColors.bananaSoft,
            ),
            child: const Icon(
              Icons.breakfast_dining_rounded,
              size: 44,
              color: TTColors.bananaDeep,
            ),
          ),
          const SizedBox(height: 12),
          Text('Time for a banana!', style: TTTypography.title()),
          Text(
            'Bao would love a yummy banana with you.',
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
                color: TTColors.bananaWarm,
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
              ),
              child: Text(
                'Let\'s Eat!',
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
