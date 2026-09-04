import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/feed_foods.dart';
import '../../models/rewards.dart';
import '../../services/feed_due_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/due_count_badge.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Single food sub-activity — one bottom bubble with a due badge (Play-style).
/// Due tap → [FeedDueStore.starsDue]; bonus tap → [FeedDueStore.starsBonus].
class EatFoodScreen extends StatefulWidget {
  const EatFoodScreen({super.key, required this.foodId});

  final String foodId;

  @override
  State<EatFoodScreen> createState() => _EatFoodScreenState();
}

class _EatFoodScreenState extends State<EatFoodScreen>
    with TickerProviderStateMixin {
  static const _crossfadeDuration = Duration(milliseconds: 550);
  static const _bubbleSize = 96.0;

  late final FeedFoodSpec _food;
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
    _food = FeedFoods.byId(widget.foodId) ?? FeedFoods.all.first;
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
    final due = await FeedDueStore.dueCount(_food.id);
    if (!mounted) return;
    setState(() => _dueCount = due);
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_food.idleVideoAsset);
    final action = VideoPlayerController.asset(_food.actionVideoAsset);

    try {
      await Future.wait([idle.initialize(), action.initialize()]);
      if (!mounted) {
        await idle.dispose();
        await action.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
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
      await idle.play();

      if (!mounted) {
        await idle.dispose();
        await action.dispose();
        return;
      }

      setState(() {
        _idleVideo = idle;
        _actionVideo = action;
        _idleReady = true;
        _actionReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await action.dispose();
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

    await _playActionAnimation();
    if (!mounted) return;

    final result = await FeedDueStore.completeOneFeed(_food.id);
    await StarsStore.add(result.stars);
    if (!mounted) return;

    setState(() => _dueCount = result.remainingDue);

    final reward = RewardResult(
      stars: result.stars,
      magicBeans: 0,
      message: result.wasDue
          ? 'Due ${_food.label.toLowerCase()} done! +${result.stars} stars'
          : 'Bonus ${_food.label.toLowerCase()}! +${result.stars} stars',
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
    final due = _dueCount > 0;

    return Scaffold(
      backgroundColor: TTColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _food.accent.withValues(alpha: 0.35),
                  TTColors.cream,
                  TTColors.momoCoral.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          _FeedVideoLayer(controller: _idleVideo, ready: _idleReady),
          AnimatedBuilder(
            animation: _crossfade,
            builder: (context, child) {
              return Opacity(
                opacity: Curves.easeInOut.transform(_crossfade.value),
                child: child,
              );
            },
            child: _FeedVideoLayer(controller: _actionVideo, ready: _actionReady),
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
                '${_food.label} with Bao!',
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
                        return Stack(
                          children: [
                            Positioned(
                              left: x,
                              bottom: 48 + bob,
                              child: BounceButton(
                                onPressed:
                                    !_actionInProgress ? _tapBubble : null,
                                enabled: !_actionInProgress,
                                semanticLabel: _food.label,
                                child: _FoodBubble(
                                  icon: _food.icon,
                                  accent: _food.accent,
                                  highlighted: due,
                                  playing: _actionInProgress,
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

class _FeedVideoLayer extends StatelessWidget {
  const _FeedVideoLayer({
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

class _FoodBubble extends StatelessWidget {
  const _FoodBubble({
    required this.icon,
    required this.accent,
    required this.highlighted,
    required this.playing,
    required this.badgeCount,
  });

  final IconData icon;
  final Color accent;
  final bool highlighted;
  final bool playing;
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
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    accent.withValues(alpha: 0.45),
                    accent.withValues(alpha: 0.7),
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
                    color: accent.withValues(alpha: highlighted ? 0.5 : 0.28),
                    blurRadius: highlighted ? 18 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 40, color: TTColors.darkBrown),
            DueCountBadge(count: badgeCount),
          ],
        ),
      ),
    );
  }
}
