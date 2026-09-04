import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/character_bg_videos.dart';
import '../../models/play_games.dart';
import '../../models/rewards.dart';
import '../../services/play_due_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Single game sub-activity — one floating bubble with a due badge.
/// Due tap → 100 stars; bonus tap → 20 stars.
class PlayGameScreen extends StatefulWidget {
  const PlayGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen>
    with TickerProviderStateMixin {
  static const _fallbackIdleVideoAsset = CharacterBgVideos.fallback;
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final PlayGameSpec _game;
  late final AnimationController _float;
  late final AnimationController _crossfade;
  bool _actionInProgress = false;
  int _dueCount = 0;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _actionVideo;
  bool _idleReady = false;
  bool _actionReady = false;
  VoidCallback? _actionListener;
  Completer<void>? _actionDone;

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
    unawaited(_refreshMeta());
  }

  Future<void> _refreshMeta() async {
    final due = await PlayDueStore.dueCount(_game.id);
    if (!mounted) return;
    setState(() {
      _dueCount = due;
    });
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
          final nearEnd =
              v.value.position >= duration - const Duration(milliseconds: 80);
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

    _actionDone = Completer<void>();
    setState(() => _actionInProgress = true);

    await action.seekTo(Duration.zero);
    await action.play();
    if (!mounted) return;

    await _crossfade.forward();
    await _actionDone?.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  Future<void> _finishAction() async {
    if (!_actionInProgress) return;

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
    if (_actionDone != null && !_actionDone!.isCompleted) {
      _actionDone!.complete();
    }
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

  Future<void> _tapBubble() async {
    if (_actionInProgress) return;

    if (_game.hasVideos) {
      await _playActionAnimation();
    } else {
      setState(() => _actionInProgress = true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _actionInProgress = false);
    }
    if (!mounted) return;

    final result = await PlayDueStore.completeOnePlay(_game.id);
    await StarsStore.add(result.stars);
    if (!mounted) return;

    setState(() {
      _dueCount = result.remainingDue;
    });

    final reward = RewardResult(
      stars: result.stars,
      magicBeans: 0,
      message: result.wasDue
          ? 'Due ${_game.label.toLowerCase()} done! +${result.stars} stars'
          : 'Bonus ${_game.label.toLowerCase()}! +${result.stars} stars',
    );
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
    const bubbleSize = 96.0;
    final due = _dueCount > 0;

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
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                '${_game.label} with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bob = math.sin(_float.value * math.pi * 2) * 12;
                        final x = constraints.maxWidth / 2 - bubbleSize / 2;
                        return Stack(
                          children: [
                            Positioned(
                              left: x,
                              bottom: 48 + bob,
                              child: BounceButton(
                                onPressed:
                                    _actionInProgress ? null : _tapBubble,
                                enabled: !_actionInProgress,
                                semanticLabel: _game.label,
                                child: PlayGameBubble(
                                  icon: _game.icon,
                                  accent: _game.accent,
                                  done: false,
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
    this.highlighted = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final Color accent;
  final bool done;
  final bool playing;
  final bool highlighted;
  final int badgeCount;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(accent, TTColors.golden, 0.35)!;

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
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    tint.withValues(alpha: highlighted ? 0.65 : 0.45),
                    accent.withValues(alpha: highlighted ? 0.75 : 0.55),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: highlighted
                      ? accent
                      : Colors.white.withValues(alpha: 0.90),
                  width: highlighted ? 4 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: highlighted ? 0.5 : 0.28),
                    blurRadius: highlighted ? 18 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 38,
              color: TTColors.darkBrown.withValues(alpha: 0.85),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TTColors.ribbonOrange,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: TTShadows.soft,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
