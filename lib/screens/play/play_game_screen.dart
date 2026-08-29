import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/play_games.dart';
import '../../models/rewards.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Single game sub-activity (under Play) — tap floating play bubbles (max 4).
/// Games with video assets crossfade idle → action like Feed/Chores activities.
class PlayGameScreen extends StatefulWidget {
  const PlayGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen>
    with TickerProviderStateMixin {
  static const _fallbackIdleVideoAsset =
      'assets/videos/bao_character_screen_bg_video.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final PlayGameSpec _game;
  late final AnimationController _float;
  late final AnimationController _crossfade;
  final Set<int> _done = {};
  bool _celebrating = false;
  bool _actionInProgress = false;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _actionVideo;
  bool _idleReady = false;
  bool _actionReady = false;
  VoidCallback? _actionListener;

  @override
  void initState() {
    super.initState();
    _game = PlayGames.byId(widget.gameId) ?? PlayGames.all.first;
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
    final idleAsset = _game.idleVideoAsset ?? _fallbackIdleVideoAsset;
    final idle = VideoPlayerController.asset(idleAsset);

    VideoPlayerController? action;
    if (_game.hasVideos) {
      action = VideoPlayerController.asset(_game.actionVideoAsset!);
    }

    try {
      if (action != null) {
        await Future.wait([idle.initialize(), action.initialize()]);
      } else {
        await idle.initialize();
      }

      if (!mounted) {
        await idle.dispose();
        await action?.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      if (action != null) {
        await action.setLooping(false);
        await action.setVolume(0);

        _actionListener = () {
          final v = _actionVideo;
          if (v == null || !_actionInProgress || !v.value.isInitialized) return;
          final duration = v.value.duration;
          if (duration <= Duration.zero) return;
          final nearEnd = v.value.position >=
              duration - const Duration(milliseconds: 80);
          if (nearEnd && !v.value.isPlaying) {
            unawaited(_finishAction());
          }
        };
        action.addListener(_actionListener!);
      }

      await idle.play();

      if (!mounted) {
        await idle.dispose();
        await action?.dispose();
        return;
      }

      setState(() {
        _idleVideo = idle;
        _actionVideo = action;
        _idleReady = true;
        _actionReady = action != null;
      });
    } catch (_) {
      await idle.dispose();
      await action?.dispose();
    }
  }

  Future<void> _playActionAnimation() async {
    final action = _actionVideo;
    if (action == null || !_actionReady || _actionInProgress) return;

    setState(() => _actionInProgress = true);

    await action.seekTo(Duration.zero);
    await action.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishAction() async {
    if (!_actionInProgress) return;

    if (_celebrating) {
      final action = _actionVideo;
      if (action != null && action.value.isInitialized) {
        await action.setLooping(true);
        await action.seekTo(Duration.zero);
        await action.play();
      }
      return;
    }

    final action = _actionVideo;
    final idle = _idleVideo;

    action?.pause();
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
    final listener = _actionListener;
    if (listener != null) {
      _actionVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _actionVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble(int index) async {
    if (_celebrating || _done.contains(index) || _actionInProgress) return;

    setState(() => _done.add(index));

    if (_game.hasVideos) {
      unawaited(_playActionAnimation());
    } else {
      setState(() => _actionInProgress = true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _actionInProgress = false);
    }

    if (_done.length >= PlayGameRules.stepsForFullReward) {
      setState(() => _celebrating = true);
      final reward = PlayGameRules.rewardForGame(_game.label, _done.length);
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
    final remaining = PlayGameRules.maxSteps - _done.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: TTColors.goldenGlow,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _game.accent.withValues(alpha: 0.25),
                  TTColors.goldenGlow,
                  TTColors.golden.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          _PlayGameVideoLayer(
            controller: _idleVideo,
            ready: _idleReady,
          ),
          if (_game.hasVideos)
            AnimatedBuilder(
              animation: _crossfade,
              builder: (context, child) {
                return Opacity(
                  opacity: Curves.easeInOut.transform(_crossfade.value),
                  child: child,
                );
              },
              child: _PlayGameVideoLayer(
                controller: _actionVideo,
                ready: _actionReady,
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
                '${_game.label} with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — great playing!'
                    : 'Tap the play bubbles ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(PlayGameRules.maxSteps, (i) {
                            final angle = (i / PlayGameRules.maxSteps) *
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
                                semanticLabel: '${_game.label} bubble ${i + 1}',
                                child: PlayGameBubble(
                                  icon: _game.icon,
                                  accent: _game.accent,
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

class _PlayGameVideoLayer extends StatelessWidget {
  const _PlayGameVideoLayer({
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

class PlayGameBubble extends StatelessWidget {
  const PlayGameBubble({
    super.key,
    required this.icon,
    required this.accent,
    required this.done,
    this.playing = false,
  });

  final IconData icon;
  final Color accent;
  final bool done;
  final bool playing;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(accent, TTColors.golden, 0.35)!;

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
                          tint.withValues(alpha: 0.55),
                          accent.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          tint.withValues(alpha: 0.45),
                          accent.withValues(alpha: 0.55),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
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
            Icon(
              icon,
              size: 34,
              color: done
                  ? accent.withValues(alpha: 0.95)
                  : TTColors.darkBrown.withValues(alpha: 0.85),
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
