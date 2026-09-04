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

/// Bath — one bottom bubble with a due badge (up to 4× / day).
/// Tap anytime: due = 10★, else 5★.
class BathScreen extends StatefulWidget {
  const BathScreen({super.key});

  @override
  State<BathScreen> createState() => _BathScreenState();
}

class _BathScreenState extends State<BathScreen>
    with TickerProviderStateMixin {
  static const _idleVideoAsset =
      'assets/videos/chore/bath/bao_not_taking_a_bath_video.mp4';
  static const _bathingVideoAsset =
      'assets/videos/chore/bath/bao_taking_a_bath_video.mp4';
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
  VideoPlayerController? _bathingVideo;
  bool _idleReady = false;
  bool _bathingReady = false;
  VoidCallback? _bathingListener;

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
    final due = await ScheduleStore.dueCount(ActivityId.bath);
    if (!mounted) return;
    setState(() => _dueCount = due);
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_idleVideoAsset);
    final bathing = VideoPlayerController.asset(_bathingVideoAsset);

    try {
      await Future.wait([idle.initialize(), bathing.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await bathing.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await bathing.setLooping(false);
      await bathing.setVolume(0);
      await idle.play();

      _bathingListener = () {
        final v = _bathingVideo;
        if (v == null || !_actionInProgress || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishAction());
        }
      };
      bathing.addListener(_bathingListener!);

      setState(() {
        _idleVideo = idle;
        _bathingVideo = bathing;
        _idleReady = true;
        _bathingReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await bathing.dispose();
    }
  }

  Future<void> _playBathingAnimation() async {
    final bathing = _bathingVideo;
    if (bathing == null || !_bathingReady || _actionInProgress) return;

    _actionDone = Completer<void>();
    setState(() => _actionInProgress = true);

    await bathing.seekTo(Duration.zero);
    await bathing.play();
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
      final bathing = _bathingVideo;
      if (bathing != null && bathing.value.isInitialized) {
        await bathing.setLooping(true);
        await bathing.seekTo(Duration.zero);
        await bathing.play();
      }
      if (_actionDone != null && !_actionDone!.isCompleted) {
        _actionDone!.complete();
      }
      return;
    }

    final bathing = _bathingVideo;
    final idle = _idleVideo;

    bathing?.pause();
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
    final listener = _bathingListener;
    if (listener != null) {
      _bathingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _bathingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble() async {
    if (_celebrating || _actionInProgress) return;

    await _playBathingAnimation();
    if (!mounted) return;

    final result = await ScheduleStore.completeOneDue(ActivityId.bath);
    await StarsStore.add(result.stars);
    if (!mounted) return;

    setState(() {
      _dueCount = result.remainingDue;
      if (result.wasDue) _clearedThisSession++;
      _celebrating = true;
    });

    final reward = ChoreDueTapRules.rewardForTap(
      wasDue: result.wasDue,
      choreLabel: 'bath',
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
      backgroundColor: TTColors.bathCream,
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
                  TTColors.bathCream,
                  TTColors.bathSoft,
                ],
              ),
            ),
          ),
          _BathVideoLayer(controller: _idleVideo, ready: _idleReady),
          AnimatedBuilder(
            animation: _crossfade,
            builder: (context, child) {
              return Opacity(
                opacity: Curves.easeInOut.transform(_crossfade.value),
                child: child,
              );
            },
            child: _BathVideoLayer(
              controller: _bathingVideo,
              ready: _bathingReady,
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
                'Bath time',
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
                                semanticLabel: 'Bath',
                                child: BathBubble(
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

class _BathVideoLayer extends StatelessWidget {
  const _BathVideoLayer({
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

class BathBubble extends StatelessWidget {
  const BathBubble({
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
                          TTColors.bathSoft.withValues(alpha: 0.55),
                          TTColors.bathWarm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.bathCream.withValues(alpha: 0.45),
                          TTColors.bathSoft.withValues(alpha: 0.55),
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
                    color: TTColors.bathWarm
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
              Icons.bathtub_rounded,
              size: 40,
              color: done
                  ? TTColors.bathWarm.withValues(alpha: 0.95)
                  : TTColors.bathDeep,
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
