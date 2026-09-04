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

enum _ShoePhase {
  /// Looping no-shoes idle + shoe bubble (bottom center).
  idle,

  /// Playing putting-on-shoes clip.
  wearing,

  /// Shoes clip fading out over worn-shoes loop.
  wearingEnding,

  /// Looping shoes-on; shoe bubble left, bag bubble right.
  waitBag,

  /// Playing take-bag clip.
  takingBag,

  /// Reward shown / finishing.
  done,
}

/// Wear Shoes — step 1 shoes, then step 2 bag.
class WearShoesScreen extends StatefulWidget {
  const WearShoesScreen({super.key});

  @override
  State<WearShoesScreen> createState() => _WearShoesScreenState();
}

class _WearShoesScreenState extends State<WearShoesScreen>
    with TickerProviderStateMixin {
  static const _folder = 'assets/videos/chore/wear_shoe';
  static const _idleAsset = '$_folder/bao_not_wearing_shoe.mp4';
  static const _wearingAsset = '$_folder/bao_wearing_shoe_video.mp4';
  static const _wornLoopAsset = '$_folder/bao_has_worn_shoe_loop_video.mp4';
  static const _bagAsset = '$_folder/bao_taking_bag_after_wearing_shoe.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);
  static const _bubbleSize = 96.0;

  late final AnimationController _float;
  late final AnimationController _crossfade;

  _ShoePhase _phase = _ShoePhase.idle;
  bool _celebrating = false;
  int _dueCount = 0;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _wearingVideo;
  VideoPlayerController? _wornLoopVideo;
  VideoPlayerController? _bagVideo;

  bool _idleReady = false;
  bool _wearingReady = false;
  bool _wornLoopReady = false;
  bool _bagReady = false;

  VoidCallback? _wearingListener;
  VoidCallback? _bagListener;

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
    final due = await ScheduleStore.dueCount(ActivityId.wearShoes);
    if (!mounted) return;
    setState(() => _dueCount = due);
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_idleAsset);
    final wearing = VideoPlayerController.asset(_wearingAsset);
    final wornLoop = VideoPlayerController.asset(_wornLoopAsset);
    final bag = VideoPlayerController.asset(_bagAsset);

    try {
      await Future.wait([
        idle.initialize(),
        wearing.initialize(),
        wornLoop.initialize(),
        bag.initialize(),
      ]);
      if (!mounted) {
        await idle.dispose();
        await wearing.dispose();
        await wornLoop.dispose();
        await bag.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await wearing.setLooping(false);
      await wearing.setVolume(0);
      await wornLoop.setLooping(true);
      await wornLoop.setVolume(0);
      await bag.setLooping(false);
      await bag.setVolume(0);
      await idle.play();

      _wearingListener = () {
        final v = _wearingVideo;
        if (v == null ||
            _phase != _ShoePhase.wearing ||
            !v.value.isInitialized) {
          return;
        }
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_onWearingClipEnded());
        }
      };
      wearing.addListener(_wearingListener!);

      _bagListener = () {
        final v = _bagVideo;
        if (v == null ||
            _phase != _ShoePhase.takingBag ||
            !v.value.isInitialized) {
          return;
        }
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_onBagClipEnded());
        }
      };
      bag.addListener(_bagListener!);

      setState(() {
        _idleVideo = idle;
        _wearingVideo = wearing;
        _wornLoopVideo = wornLoop;
        _bagVideo = bag;
        _idleReady = true;
        _wearingReady = true;
        _wornLoopReady = true;
        _bagReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await wearing.dispose();
      await wornLoop.dispose();
      await bag.dispose();
    }
  }

  Future<void> _tapShoe() async {
    if (_phase != _ShoePhase.idle || _celebrating) return;
    final wearing = _wearingVideo;
    if (wearing == null || !_wearingReady) return;

    setState(() => _phase = _ShoePhase.wearing);
    await wearing.seekTo(Duration.zero);
    await wearing.play();
    if (!mounted) return;
    await _crossfade.forward();
  }

  Future<void> _onWearingClipEnded() async {
    if (_phase != _ShoePhase.wearing) return;

    final wearing = _wearingVideo;
    final idle = _idleVideo;
    final wornLoop = _wornLoopVideo;

    wearing?.pause();
    idle?.pause();

    if (wornLoop != null && wornLoop.value.isInitialized) {
      await wornLoop.seekTo(Duration.zero);
      await wornLoop.play();
    }
    if (!mounted) return;

    setState(() => _phase = _ShoePhase.wearingEnding);
    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _phase = _ShoePhase.waitBag);
  }

  Future<void> _tapBag() async {
    if (_phase != _ShoePhase.waitBag || _celebrating) return;
    final bag = _bagVideo;
    if (bag == null || !_bagReady) return;

    setState(() => _phase = _ShoePhase.takingBag);
    await bag.seekTo(Duration.zero);
    await bag.play();
    if (!mounted) return;
    await _crossfade.forward();
  }

  Future<void> _onBagClipEnded() async {
    if (_phase != _ShoePhase.takingBag || _celebrating) return;

    setState(() {
      _phase = _ShoePhase.done;
      _celebrating = true;
    });

    final bag = _bagVideo;
    if (bag != null && bag.value.isInitialized) {
      await bag.setLooping(true);
      await bag.seekTo(Duration.zero);
      await bag.play();
    }

    final reward = WearShoesRules.rewardForSteps(2);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await StarsStore.add(reward.stars);
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
  void dispose() {
    final wearingListener = _wearingListener;
    if (wearingListener != null) {
      _wearingVideo?.removeListener(wearingListener);
    }
    final bagListener = _bagListener;
    if (bagListener != null) {
      _bagVideo?.removeListener(bagListener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _wearingVideo?.dispose();
    _wornLoopVideo?.dispose();
    _bagVideo?.dispose();
    super.dispose();
  }

  bool get _showBagBubble =>
      _phase == _ShoePhase.wearingEnding ||
      _phase == _ShoePhase.waitBag ||
      _phase == _ShoePhase.takingBag ||
      _phase == _ShoePhase.done;

  bool get _shoeCompleted =>
      _phase == _ShoePhase.waitBag ||
      _phase == _ShoePhase.takingBag ||
      _phase == _ShoePhase.done ||
      _phase == _ShoePhase.wearingEnding;

  bool get _bagCompleted => _phase == _ShoePhase.done;

  bool get _busy =>
      _phase == _ShoePhase.wearing ||
      _phase == _ShoePhase.wearingEnding ||
      _phase == _ShoePhase.takingBag;

  VideoPlayerController? get _baseController {
    switch (_phase) {
      case _ShoePhase.idle:
      case _ShoePhase.wearing:
        return _idleVideo;
      case _ShoePhase.wearingEnding:
      case _ShoePhase.waitBag:
      case _ShoePhase.takingBag:
      case _ShoePhase.done:
        return _wornLoopVideo;
    }
  }

  bool get _baseReady {
    switch (_phase) {
      case _ShoePhase.idle:
      case _ShoePhase.wearing:
        return _idleReady;
      case _ShoePhase.wearingEnding:
      case _ShoePhase.waitBag:
      case _ShoePhase.takingBag:
      case _ShoePhase.done:
        return _wornLoopReady;
    }
  }

  VideoPlayerController? get _overlayController {
    switch (_phase) {
      case _ShoePhase.wearing:
      case _ShoePhase.wearingEnding:
        return _wearingVideo;
      case _ShoePhase.takingBag:
      case _ShoePhase.done:
        return _bagVideo;
      case _ShoePhase.idle:
      case _ShoePhase.waitBag:
        return null;
    }
  }

  bool get _overlayReady {
    switch (_phase) {
      case _ShoePhase.wearing:
      case _ShoePhase.wearingEnding:
        return _wearingReady;
      case _ShoePhase.takingBag:
      case _ShoePhase.done:
        return _bagReady;
      case _ShoePhase.idle:
      case _ShoePhase.waitBag:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayVisible = _phase == _ShoePhase.wearing ||
        _phase == _ShoePhase.wearingEnding ||
        _phase == _ShoePhase.takingBag ||
        _phase == _ShoePhase.done;

    return Scaffold(
      backgroundColor: TTColors.shoeCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  TTColors.shoeCream,
                  TTColors.shoeSoft,
                ],
              ),
            ),
          ),
          _ShoeVideoLayer(
            controller: _baseController,
            ready: _baseReady,
          ),
          if (overlayVisible)
            AnimatedBuilder(
              animation: _crossfade,
              builder: (context, child) {
                final opacity = _phase == _ShoePhase.done
                    ? 1.0
                    : Curves.easeInOut.transform(_crossfade.value);
                return Opacity(opacity: opacity, child: child);
              },
              child: _ShoeVideoLayer(
                controller: _overlayController,
                ready: _overlayReady,
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
                'Wear Shoes!',
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
                            math.sin(_float.value * math.pi * 2) * 10;
                        final centerX =
                            constraints.maxWidth / 2 - _bubbleSize / 2;
                        final leftX =
                            constraints.maxWidth * 0.22 - _bubbleSize / 2;
                        final rightX =
                            constraints.maxWidth * 0.78 - _bubbleSize / 2;
                        final shoeX = _showBagBubble ? leftX : centerX;

                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              left: shoeX,
                              bottom: 48 + bob,
                              child: BounceButton(
                                onPressed: _phase == _ShoePhase.idle && !_busy
                                    ? _tapShoe
                                    : null,
                                enabled: _phase == _ShoePhase.idle && !_busy,
                                semanticLabel: 'Shoes',
                                child: _ShoeStepBubble(
                                  icon: Icons.snowshoeing_rounded,
                                  accent: TTColors.shoeDeep,
                                  soft: TTColors.shoeSoft,
                                  cream: TTColors.shoeCream,
                                  warm: TTColors.shoeWarm,
                                  done: _shoeCompleted,
                                  playing: _phase == _ShoePhase.wearing ||
                                      _phase == _ShoePhase.wearingEnding,
                                  highlighted:
                                      _dueCount > 0 && _phase == _ShoePhase.idle,
                                  badgeCount: _phase == _ShoePhase.idle
                                      ? _dueCount
                                      : 0,
                                ),
                              ),
                            ),
                            if (_showBagBubble)
                              Positioned(
                                left: rightX,
                                bottom: 48 - bob,
                                child: BounceButton(
                                  onPressed:
                                      _phase == _ShoePhase.waitBag && !_busy
                                          ? _tapBag
                                          : null,
                                  enabled:
                                      _phase == _ShoePhase.waitBag && !_busy,
                                  semanticLabel: 'Bag',
                                  child: _ShoeStepBubble(
                                    icon: Icons.backpack_rounded,
                                    accent: TTColors.shoeDeep,
                                    soft: TTColors.shoeSoft,
                                    cream: TTColors.shoeCream,
                                    warm: TTColors.shoeWarm,
                                    done: _bagCompleted,
                                    playing: _phase == _ShoePhase.takingBag,
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

class _ShoeVideoLayer extends StatelessWidget {
  const _ShoeVideoLayer({
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

class _ShoeStepBubble extends StatelessWidget {
  const _ShoeStepBubble({
    required this.icon,
    required this.accent,
    required this.soft,
    required this.cream,
    required this.warm,
    required this.done,
    this.playing = false,
    this.highlighted = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final Color accent;
  final Color soft;
  final Color cream;
  final Color warm;
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
                          soft.withValues(alpha: 0.55),
                          warm.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          cream.withValues(alpha: 0.45),
                          soft.withValues(alpha: 0.55),
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
                    color: warm.withValues(alpha: 0.28),
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
            Icon(
              icon,
              size: 38,
              color: done ? warm.withValues(alpha: 0.95) : accent,
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
