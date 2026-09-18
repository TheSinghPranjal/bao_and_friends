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
  late final AnimationController _entrance;
  late final AnimationController _orbit;
  late final AnimationController _burst;
  final math.Random _rng = math.Random();
  List<_BurstParticle> _burstParticles = const [];
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
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    unawaited(_initVideos());
    unawaited(_refreshMeta());
  }

  void _spawnBurst() {
    _burstParticles = List.generate(10, (i) {
      final angle = (i / 10) * math.pi * 2 + _rng.nextDouble() * 0.4;
      return _BurstParticle(
        angle: angle,
        distance: 46 + _rng.nextDouble() * 42,
        size: 5 + _rng.nextDouble() * 6,
        isStar: _rng.nextBool(),
      );
    });
    _burst.forward(from: 0);
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
    _entrance.dispose();
    _orbit.dispose();
    _burst.dispose();
    _idleVideo?.dispose();
    _actionVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapBubble() async {
    if (_actionInProgress) return;

    _spawnBurst();

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
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _game.accent.withValues(alpha: 0.22),
                  ],
                  stops: const [0.72, 1.0],
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
              FadeTransition(
                opacity: _entrance,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.15),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entrance,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _game.accent.withValues(alpha: 0.85),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: TTShadows.soft,
                        ),
                        child: Icon(
                          _game.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Text(
                        '${_game.label} with Bao!',
                        style: TTTypography.headline(color: TTColors.darkBrown)
                            .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _entrance,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entrance,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_float, _orbit, _burst]),
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final bob =
                                math.sin(_float.value * math.pi * 2) * 12;
                            final x =
                                constraints.maxWidth / 2 - bubbleSize / 2;
                            final liftT = ((bob + 12) / 24).clamp(0.0, 1.0);
                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  bottom: 40,
                                  child: Container(
                                    width: bubbleSize *
                                        (0.75 - liftT * 0.18),
                                    height: 16 - liftT * 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: TTColors.darkBrown.withValues(
                                        alpha: 0.22 - liftT * 0.10,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: x,
                                  bottom: 48 + bob,
                                  child: SizedBox(
                                    width: bubbleSize,
                                    height: bubbleSize,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        if (due && !_actionInProgress)
                                          ..._orbitSparkles(bubbleSize),
                                        if (_burst.isAnimating)
                                          ..._burstWidgets(bubbleSize),
                                        BounceButton(
                                          onPressed: _actionInProgress
                                              ? null
                                              : _tapBubble,
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
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: _actionInProgress ? 0.0 : 0.65 +
                                        math.sin(_float.value * math.pi * 2) *
                                            0.2,
                                    child: Text(
                                      due
                                          ? 'Tap Bao — it\'s ${_game.label.toLowerCase()} time!'
                                          : 'Tap Bao to play ${_game.label.toLowerCase()}!',
                                      style: TTTypography.caption(
                                        color: TTColors.darkBrown,
                                      ).copyWith(fontWeight: FontWeight.w700),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _orbitSparkles(double bubbleSize) {
    const count = 3;
    final radius = bubbleSize / 2 + 14;
    return [
      for (var i = 0; i < count; i++)
        Builder(
          builder: (context) {
            final angle =
                _orbit.value * math.pi * 2 + (i / count) * math.pi * 2;
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * radius,
                math.sin(angle) * radius * 0.6,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: _game.accent.withValues(alpha: 0.85),
              ),
            );
          },
        ),
    ];
  }

  List<Widget> _burstWidgets(double bubbleSize) {
    final t = Curves.easeOut.transform(_burst.value);
    final fade = (1 - _burst.value).clamp(0.0, 1.0);
    return [
      for (final p in _burstParticles)
        Transform.translate(
          offset: Offset(
            math.cos(p.angle) * p.distance * t,
            math.sin(p.angle) * p.distance * t,
          ),
          child: Opacity(
            opacity: fade,
            child: p.isStar
                ? Icon(
                    Icons.star_rounded,
                    size: p.size + 4,
                    color: TTColors.golden,
                  )
                : Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _game.accent,
                    ),
                  ),
          ),
        ),
    ];
  }
}

class _BurstParticle {
  const _BurstParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.isStar,
  });

  final double angle;
  final double distance;
  final double size;
  final bool isStar;
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
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(badgeCount),
                  tween: Tween(begin: 0.4, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
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
              ),
          ],
        ),
      ),
    );
  }
}
