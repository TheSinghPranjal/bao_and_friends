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
import '../../widgets/due_count_badge.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Brush Teeth — one bottom bubble with a due badge (up to 4× / day).
/// Tap anytime: due = 10★, else 5★.
class BrushTeethScreen extends StatefulWidget {
  const BrushTeethScreen({super.key});

  @override
  State<BrushTeethScreen> createState() => _BrushTeethScreenState();
}

class _BrushTeethScreenState extends State<BrushTeethScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/chore/brush/bao_not_brushing_teeth.mp4';
  static const _brushingVideoAsset =
      'assets/videos/chore/brush/bao_brushing_teeth.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);
  static const _bubbleSize = 96.0;

  late final AnimationController _float;
  late final AnimationController _crossfade;
  bool _celebrating = false;
  bool _actionInProgress = false;
  int _dueCount = 0;
  int _clearedThisSession = 0;
  Completer<void>? _actionDone;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _brushingVideo;
  bool _idleReady = false;
  bool _brushingReady = false;
  VoidCallback? _brushingListener;

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
    unawaited(_loadDue());
  }

  Future<void> _loadDue() async {
    final due = await ScheduleStore.dueCount(ActivityId.brushTeeth);
    if (!mounted) return;
    setState(() => _dueCount = due);
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_idleVideoAsset);
    final brushing = VideoPlayerController.asset(_brushingVideoAsset);

    try {
      await Future.wait([idle.initialize(), brushing.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await brushing.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await brushing.setLooping(false);
      await brushing.setVolume(0);
      await idle.play();

      _brushingListener = () {
        final v = _brushingVideo;
        if (v == null || !_actionInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishAction());
        }
      };
      brushing.addListener(_brushingListener!);

      setState(() {
        _idleVideo = idle;
        _brushingVideo = brushing;
        _idleReady = true;
        _brushingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await brushing.dispose();
    }
  }

  Future<void> _playBrushingAnimation() async {
    final brushing = _brushingVideo;
    if (brushing == null || !_brushingReady || _actionInProgress) return;

    _actionDone = Completer<void>();
    setState(() => _actionInProgress = true);

    await brushing.seekTo(Duration.zero);
    await brushing.play();
    if (!mounted) return;

    await _crossfade.forward();
    await _actionDone?.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  Future<void> _finishAction() async {
    if (!_actionInProgress) return;

    if (_celebrating) {
      final brushing = _brushingVideo;
      if (brushing != null && brushing.value.isInitialized) {
        await brushing.setLooping(true);
        await brushing.seekTo(Duration.zero);
        await brushing.play();
      }
      if (_actionDone != null && !_actionDone!.isCompleted) {
        _actionDone!.complete();
      }
      return;
    }

    final brushing = _brushingVideo;
    final idle = _idleVideo;

    brushing?.pause();
    if (idle != null && idle.value.isInitialized && !idle.value.isPlaying) {
      await idle.play();
    }
    if (!mounted) return;

    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    if (_actionDone != null && !_actionDone!.isCompleted) {
      _actionDone!.complete();
    }
  }

  @override
  void dispose() {
    final listener = _brushingListener;
    if (listener != null) {
      _brushingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _brushingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble() async {
    if (_celebrating || _actionInProgress) return;

    await _playBrushingAnimation();
    if (!mounted) return;

    final result =
        await ScheduleStore.completeOneDue(ActivityId.brushTeeth);
    await StarsStore.add(result.stars);
    if (!mounted) return;

    setState(() {
      _dueCount = result.remainingDue;
      if (result.wasDue) _clearedThisSession++;
      _celebrating = true;
    });

    final reward = ChoreDueTapRules.rewardForTap(
      wasDue: result.wasDue,
      choreLabel: 'brush teeth',
    );
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await _showReward(reward);
    if (!mounted) return;
    context.pop(true);
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
    return Scaffold(
      backgroundColor: TTColors.teethCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F7FA),
                  TTColors.teethCream,
                  TTColors.teethSoft,
                ],
              ),
            ),
          ),
          _TeethVideoLayer(controller: _idleVideo, ready: _idleReady),
          AnimatedBuilder(
            animation: _crossfade,
            builder: (context, child) {
              return Opacity(
                opacity: Curves.easeInOut.transform(_crossfade.value),
                child: child,
              );
            },
            child: _TeethVideoLayer(
              controller: _brushingVideo,
              ready: _brushingReady,
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
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                'Brush teeth',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bob =
                            math.sin(_float.value * math.pi * 2) * 12;
                        final x = constraints.maxWidth / 2 - _bubbleSize / 2;
                        final due = _dueCount > 0;
                        return Stack(
                          children: [
                            Positioned(
                              left: x,
                              bottom: 48 + bob,
                              child: BounceButton(
                                onPressed: !_actionInProgress && !_celebrating
                                    ? _tapBubble
                                    : null,
                                enabled: !_actionInProgress && !_celebrating,
                                semanticLabel: 'Brush teeth',
                                child: TeethBubble(
                                  done: !due && _clearedThisSession > 0,
                                  playing: _actionInProgress,
                                  highlighted: due,
                                  badgeCount: _dueCount,
                                ),
                              ),
                            ),
                          ],
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

class _TeethVideoLayer extends StatelessWidget {
  const _TeethVideoLayer({
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

class TeethBubble extends StatelessWidget {
  const TeethBubble({
    super.key,
    required this.done,
    this.playing = false,
    this.highlighted = false,
    this.badgeCount = 0,
  });

  final bool done;
  final bool playing;
  final bool highlighted;
  final int badgeCount;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: playing ? 1.12 : (highlighted ? 1.06 : 1.0),
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
                          TTColors.teethSoft.withValues(alpha: 0.55),
                          TTColors.teethWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.teethCream.withValues(alpha: 0.45),
                          TTColors.teethSoft.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: highlighted
                      ? TTColors.ribbonOrange
                      : Colors.white.withValues(alpha: 0.90),
                  width: highlighted ? 4 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.teethWarm
                        .withValues(alpha: highlighted ? 0.5 : 0.28),
                    blurRadius: highlighted ? 18 : 14,
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
            Icon(
              Icons.clean_hands_rounded,
              size: 40,
              color: done
                  ? TTColors.teethWarm.withValues(alpha: 0.95)
                  : TTColors.teethDeep,
            ),
            DueCountBadge(count: badgeCount),
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
