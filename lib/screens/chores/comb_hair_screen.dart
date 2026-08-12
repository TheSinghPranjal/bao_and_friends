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

/// Comb Hair Activity (under Chores) — tap floating comb bubbles (max 4).
/// 1 tap → 1 star. All 4 → 3 stars + 1 Magic Bean.
class CombHairScreen extends StatefulWidget {
  const CombHairScreen({super.key});

  @override
  State<CombHairScreen> createState() => _CombHairScreenState();
}

class _CombHairScreenState extends State<CombHairScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/chore/comb_hair/bao_not_coming_hair.mp4';
  static const _combingVideoAsset =
      'assets/videos/chore/comb_hair/bao_combing_hair.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final AnimationController _float;
  late final AnimationController _crossfade;
  final Set<int> _done = {};
  bool _celebrating = false;
  bool _actionInProgress = false;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _combingVideo;
  bool _idleReady = false;
  bool _combingReady = false;
  VoidCallback? _combingListener;

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
    final combing = VideoPlayerController.asset(_combingVideoAsset);

    try {
      await Future.wait([idle.initialize(), combing.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await combing.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await combing.setLooping(false);
      await combing.setVolume(0);
      await idle.play();

      _combingListener = () {
        final v = _combingVideo;
        if (v == null || !_actionInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd = v.value.position >=
            duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishAction());
        }
      };
      combing.addListener(_combingListener!);

      setState(() {
        _idleVideo = idle;
        _combingVideo = combing;
        _idleReady = true;
        _combingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await combing.dispose();
    }
  }

  Future<void> _playCombingAnimation() async {
    final combing = _combingVideo;
    if (combing == null || !_combingReady || _actionInProgress) return;

    setState(() => _actionInProgress = true);

    await combing.seekTo(Duration.zero);
    await combing.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishAction() async {
    if (!_actionInProgress) return;

    if (_celebrating) {
      final combing = _combingVideo;
      if (combing != null && combing.value.isInitialized) {
        await combing.setLooping(true);
        await combing.seekTo(Duration.zero);
        await combing.play();
      }
      return;
    }

    final combing = _combingVideo;
    final idle = _idleVideo;

    combing?.pause();
    if (idle != null && idle.value.isInitialized && !idle.value.isPlaying) {
      await idle.play();
    }
    if (!mounted) return;

    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _actionInProgress = false);
  }

  @override
  void dispose() {
    final listener = _combingListener;
    if (listener != null) {
      _combingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _combingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble(int index) async {
    if (_celebrating || _done.contains(index) || _actionInProgress) return;
    setState(() => _done.add(index));
    unawaited(_playCombingAnimation());

    if (_done.length >= CombHairRules.stepsForFullReward) {
      setState(() => _celebrating = true);
      final reward = CombHairRules.rewardForSteps(_done.length);
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
    final remaining = CombHairRules.maxSteps - _done.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: TTColors.combCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF8E1),
                  TTColors.combCream,
                  TTColors.combSoft,
                ],
              ),
            ),
          ),
          _CombVideoLayer(
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
            child: _CombVideoLayer(
              controller: _combingVideo,
              ready: _combingReady,
            ),
          ),
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
                stars: 12 + (_done.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                'Comb Hair!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so neat!'
                    : 'Tap the comb bubbles ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(CombHairRules.maxSteps, (i) {
                            final angle = (i / CombHairRules.maxSteps) *
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
                            final finished = _done.contains(i);
                            return Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed: finished || _actionInProgress
                                    ? null
                                    : () => _tapBubble(i),
                                enabled: !finished && !_actionInProgress,
                                semanticLabel: 'Comb hair bubble ${i + 1}',
                                child: CombBubble(
                                  done: finished,
                                  playing: finished && _actionInProgress,
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

class _CombVideoLayer extends StatelessWidget {
  const _CombVideoLayer({
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
          child: VideoPlayer(
            key: ValueKey(controller),
            controller!,
          ),
        ),
      ),
    );
  }
}

/// Soft comb bubble — same glassy float language as feed activity bubbles.
class CombBubble extends StatelessWidget {
  const CombBubble({super.key, required this.done, this.playing = false});

  final bool done;
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
                  colors: done
                      ? [
                          Colors.white.withValues(alpha: 0.70),
                          TTColors.combSoft.withValues(alpha: 0.55),
                          TTColors.combWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.combCream.withValues(alpha: 0.45),
                          TTColors.combSoft.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.combWarm.withValues(alpha: 0.28),
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
              Icons.content_cut_rounded,
              size: 34,
              color: done
                  ? TTColors.combWarm.withValues(alpha: 0.95)
                  : TTColors.combDeep,
            ),
            if (done)
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
