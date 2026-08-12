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

/// Make Bed Activity (under Chores) — tap floating bed bubbles (max 4).
/// 1 tap → 1 star. All 4 → 3 stars + 1 Magic Bean.
class MakeBedScreen extends StatefulWidget {
  const MakeBedScreen({super.key});

  @override
  State<MakeBedScreen> createState() => _MakeBedScreenState();
}

class _MakeBedScreenState extends State<MakeBedScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/chore/make_bed/bao_not_making_bed.mp4';
  static const _makingVideoAsset =
      'assets/videos/chore/make_bed/bao_making_bed.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final AnimationController _float;
  late final AnimationController _crossfade;
  final Set<int> _done = {};
  bool _celebrating = false;
  bool _actionInProgress = false;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _makingVideo;
  bool _idleReady = false;
  bool _makingReady = false;
  VoidCallback? _makingListener;

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
    final making = VideoPlayerController.asset(_makingVideoAsset);

    try {
      await Future.wait([idle.initialize(), making.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await making.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await making.setLooping(false);
      await making.setVolume(0);
      await idle.play();

      _makingListener = () {
        final v = _makingVideo;
        if (v == null || !_actionInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd = v.value.position >=
            duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishAction());
        }
      };
      making.addListener(_makingListener!);

      setState(() {
        _idleVideo = idle;
        _makingVideo = making;
        _idleReady = true;
        _makingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await making.dispose();
    }
  }

  Future<void> _playMakingAnimation() async {
    final making = _makingVideo;
    if (making == null || !_makingReady || _actionInProgress) return;

    setState(() => _actionInProgress = true);

    await making.seekTo(Duration.zero);
    await making.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishAction() async {
    if (!_actionInProgress) return;

    if (_celebrating) {
      final making = _makingVideo;
      if (making != null && making.value.isInitialized) {
        await making.setLooping(true);
        await making.seekTo(Duration.zero);
        await making.play();
      }
      return;
    }

    final making = _makingVideo;
    final idle = _idleVideo;

    making?.pause();
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
    final listener = _makingListener;
    if (listener != null) {
      _makingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _makingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble(int index) async {
    if (_celebrating || _done.contains(index) || _actionInProgress) return;
    setState(() => _done.add(index));
    unawaited(_playMakingAnimation());

    if (_done.length >= MakeBedRules.stepsForFullReward) {
      setState(() => _celebrating = true);
      final reward = MakeBedRules.rewardForSteps(_done.length);
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
    final remaining = MakeBedRules.maxSteps - _done.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: TTColors.bedCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3E5F5),
                  TTColors.bedCream,
                  TTColors.bedSoft,
                ],
              ),
            ),
          ),
          _BedVideoLayer(
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
            child: _BedVideoLayer(
              controller: _makingVideo,
              ready: _makingReady,
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
                'Make the Bed!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so tidy!'
                    : 'Tap the bed bubbles ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(MakeBedRules.maxSteps, (i) {
                            final angle = (i / MakeBedRules.maxSteps) *
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
                                semanticLabel: 'Make bed bubble ${i + 1}',
                                child: BedBubble(
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

class _BedVideoLayer extends StatelessWidget {
  const _BedVideoLayer({
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

/// Cozy bed bubble — same glassy float language as feed activity bubbles.
class BedBubble extends StatelessWidget {
  const BedBubble({super.key, required this.done, this.playing = false});

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
                          TTColors.bedSoft.withValues(alpha: 0.55),
                          TTColors.bedWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.bedCream.withValues(alpha: 0.45),
                          TTColors.bedSoft.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.bedWarm.withValues(alpha: 0.28),
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
              Icons.bed_rounded,
              size: 34,
              color: done
                  ? TTColors.bedWarm.withValues(alpha: 0.95)
                  : TTColors.bedDeep,
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
