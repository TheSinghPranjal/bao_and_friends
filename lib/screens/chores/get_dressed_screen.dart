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

enum _DressPhase {
  /// Looping undressed idle + dress bubble (bottom center).
  idle,

  /// Playing clothes-on clip.
  dressing,

  /// Clothes clip fading out over no-tie loop.
  dressingEnding,

  /// Looping dressed-without-tie; dress bubble left, tie bubble right.
  waitTie,

  /// Playing tie-on clip.
  tying,

  /// Reward shown / finishing.
  done,
}

/// Get Dressed — step 1 clothes, then step 2 tie.
class GetDressedScreen extends StatefulWidget {
  const GetDressedScreen({super.key});

  @override
  State<GetDressedScreen> createState() => _GetDressedScreenState();
}

class _GetDressedScreenState extends State<GetDressedScreen>
    with TickerProviderStateMixin {
  static const _folder = 'assets/videos/chore/getting_dressed';
  static const _idleAsset = '$_folder/bao_not_getting_dressed.mp4';
  static const _dressAsset = '$_folder/bao_getting_dressed.mp4';
  static const _noTieAsset = '$_folder/bao_getting_dressed_not_wearing_tie.mp4';
  static const _tieAsset = '$_folder/bao_getting_dressed_wearing_tie.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);
  static const _bubbleSize = 96.0;

  late final AnimationController _float;
  late final AnimationController _crossfade;

  _DressPhase _phase = _DressPhase.idle;
  bool _celebrating = false;
  int _dueCount = 0;

  VideoPlayerController? _idleVideo;
  VideoPlayerController? _dressVideo;
  VideoPlayerController? _noTieVideo;
  VideoPlayerController? _tieVideo;

  bool _idleReady = false;
  bool _dressReady = false;
  bool _noTieReady = false;
  bool _tieReady = false;

  VoidCallback? _dressListener;
  VoidCallback? _tieListener;

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
    final due = await ScheduleStore.dueCount(ActivityId.getDressed);
    if (!mounted) return;
    setState(() => _dueCount = due);
  }

  Future<void> _initVideos() async {
    final idle = VideoPlayerController.asset(_idleAsset);
    final dress = VideoPlayerController.asset(_dressAsset);
    final noTie = VideoPlayerController.asset(_noTieAsset);
    final tie = VideoPlayerController.asset(_tieAsset);

    try {
      await Future.wait([
        idle.initialize(),
        dress.initialize(),
        noTie.initialize(),
        tie.initialize(),
      ]);
      if (!mounted) {
        await idle.dispose();
        await dress.dispose();
        await noTie.dispose();
        await tie.dispose();
        return;
      }

      await idle.setLooping(true);
      await idle.setVolume(0);
      await dress.setLooping(false);
      await dress.setVolume(0);
      await noTie.setLooping(true);
      await noTie.setVolume(0);
      await tie.setLooping(false);
      await tie.setVolume(0);
      await idle.play();

      _dressListener = () {
        final v = _dressVideo;
        if (v == null ||
            _phase != _DressPhase.dressing ||
            !v.value.isInitialized) {
          return;
        }
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_onDressClipEnded());
        }
      };
      dress.addListener(_dressListener!);

      _tieListener = () {
        final v = _tieVideo;
        if (v == null ||
            _phase != _DressPhase.tying ||
            !v.value.isInitialized) {
          return;
        }
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_onTieClipEnded());
        }
      };
      tie.addListener(_tieListener!);

      setState(() {
        _idleVideo = idle;
        _dressVideo = dress;
        _noTieVideo = noTie;
        _tieVideo = tie;
        _idleReady = true;
        _dressReady = true;
        _noTieReady = true;
        _tieReady = true;
      });
    } catch (_) {
      await idle.dispose();
      await dress.dispose();
      await noTie.dispose();
      await tie.dispose();
    }
  }

  Future<void> _tapDress() async {
    if (_phase != _DressPhase.idle || _celebrating) return;
    final dress = _dressVideo;
    if (dress == null || !_dressReady) return;

    setState(() => _phase = _DressPhase.dressing);
    await dress.seekTo(Duration.zero);
    await dress.play();
    if (!mounted) return;
    await _crossfade.forward();
  }

  Future<void> _onDressClipEnded() async {
    if (_phase != _DressPhase.dressing) return;

    final dress = _dressVideo;
    final idle = _idleVideo;
    final noTie = _noTieVideo;

    dress?.pause();
    idle?.pause();

    if (noTie != null && noTie.value.isInitialized) {
      await noTie.seekTo(Duration.zero);
      await noTie.play();
    }
    if (!mounted) return;

    // Keep dress overlay visible while swapping base to no-tie, then fade out.
    setState(() => _phase = _DressPhase.dressingEnding);
    await _crossfade.reverse();
    if (!mounted) return;
    setState(() => _phase = _DressPhase.waitTie);
  }

  Future<void> _tapTie() async {
    if (_phase != _DressPhase.waitTie || _celebrating) return;
    final tie = _tieVideo;
    if (tie == null || !_tieReady) return;

    setState(() => _phase = _DressPhase.tying);
    await tie.seekTo(Duration.zero);
    await tie.play();
    if (!mounted) return;
    await _crossfade.forward();
  }

  Future<void> _onTieClipEnded() async {
    if (_phase != _DressPhase.tying || _celebrating) return;

    setState(() {
      _phase = _DressPhase.done;
      _celebrating = true;
    });

    final tie = _tieVideo;
    if (tie != null && tie.value.isInitialized) {
      await tie.setLooping(true);
      await tie.seekTo(Duration.zero);
      await tie.play();
    }

    final reward = GetDressedRules.rewardForSteps(2);
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
    final dressListener = _dressListener;
    if (dressListener != null) {
      _dressVideo?.removeListener(dressListener);
    }
    final tieListener = _tieListener;
    if (tieListener != null) {
      _tieVideo?.removeListener(tieListener);
    }
    _float.dispose();
    _crossfade.dispose();
    _idleVideo?.dispose();
    _dressVideo?.dispose();
    _noTieVideo?.dispose();
    _tieVideo?.dispose();
    super.dispose();
  }

  bool get _showTieBubble =>
      _phase == _DressPhase.dressingEnding ||
      _phase == _DressPhase.waitTie ||
      _phase == _DressPhase.tying ||
      _phase == _DressPhase.done;

  bool get _dressCompleted =>
      _phase == _DressPhase.waitTie ||
      _phase == _DressPhase.tying ||
      _phase == _DressPhase.done ||
      _phase == _DressPhase.dressingEnding;

  bool get _tieCompleted => _phase == _DressPhase.done;

  bool get _busy =>
      _phase == _DressPhase.dressing ||
      _phase == _DressPhase.dressingEnding ||
      _phase == _DressPhase.tying;

  /// Base looping layer under the action crossfade.
  VideoPlayerController? get _baseController {
    switch (_phase) {
      case _DressPhase.idle:
      case _DressPhase.dressing:
        return _idleVideo;
      case _DressPhase.dressingEnding:
      case _DressPhase.waitTie:
      case _DressPhase.tying:
      case _DressPhase.done:
        return _noTieVideo;
    }
  }

  bool get _baseReady {
    switch (_phase) {
      case _DressPhase.idle:
      case _DressPhase.dressing:
        return _idleReady;
      case _DressPhase.dressingEnding:
      case _DressPhase.waitTie:
      case _DressPhase.tying:
      case _DressPhase.done:
        return _noTieReady;
    }
  }

  /// One-shot overlay (dress or tie clip).
  VideoPlayerController? get _overlayController {
    switch (_phase) {
      case _DressPhase.dressing:
      case _DressPhase.dressingEnding:
        return _dressVideo;
      case _DressPhase.tying:
      case _DressPhase.done:
        return _tieVideo;
      case _DressPhase.idle:
      case _DressPhase.waitTie:
        return null;
    }
  }

  bool get _overlayReady {
    switch (_phase) {
      case _DressPhase.dressing:
      case _DressPhase.dressingEnding:
        return _dressReady;
      case _DressPhase.tying:
      case _DressPhase.done:
        return _tieReady;
      case _DressPhase.idle:
      case _DressPhase.waitTie:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayVisible = _phase == _DressPhase.dressing ||
        _phase == _DressPhase.dressingEnding ||
        _phase == _DressPhase.tying ||
        _phase == _DressPhase.done;

    return Scaffold(
      backgroundColor: TTColors.dressCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFCE4EC),
                  TTColors.dressCream,
                  TTColors.dressSoft,
                ],
              ),
            ),
          ),
          _DressVideoLayer(
            controller: _baseController,
            ready: _baseReady,
          ),
          if (overlayVisible)
            AnimatedBuilder(
              animation: _crossfade,
              builder: (context, child) {
                final opacity = _phase == _DressPhase.done
                    ? 1.0
                    : Curves.easeInOut.transform(_crossfade.value);
                return Opacity(opacity: opacity, child: child);
              },
              child: _DressVideoLayer(
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
                'Get Dressed!',
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
                        final dressX = _showTieBubble ? leftX : centerX;

                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              left: dressX,
                              bottom: 48 + bob,
                              child: BounceButton(
                                onPressed: _phase == _DressPhase.idle && !_busy
                                    ? _tapDress
                                    : null,
                                enabled: _phase == _DressPhase.idle && !_busy,
                                semanticLabel: 'Clothes',
                                child: _StepBubble(
                                  icon: Icons.checkroom_rounded,
                                  accent: TTColors.dressDeep,
                                  soft: TTColors.dressSoft,
                                  cream: TTColors.dressCream,
                                  warm: TTColors.dressWarm,
                                  done: _dressCompleted,
                                  playing: _phase == _DressPhase.dressing ||
                                      _phase == _DressPhase.dressingEnding,
                                  highlighted:
                                      _dueCount > 0 && _phase == _DressPhase.idle,
                                  badgeCount: _phase == _DressPhase.idle
                                      ? _dueCount
                                      : 0,
                                ),
                              ),
                            ),
                            if (_showTieBubble)
                              Positioned(
                                left: rightX,
                                bottom: 48 - bob,
                                child: BounceButton(
                                  onPressed:
                                      _phase == _DressPhase.waitTie && !_busy
                                          ? _tapTie
                                          : null,
                                  enabled:
                                      _phase == _DressPhase.waitTie && !_busy,
                                  semanticLabel: 'Tie',
                                  child: _StepBubble(
                                    icon: Icons.loyalty_rounded,
                                    accent: TTColors.dressDeep,
                                    soft: TTColors.dressSoft,
                                    cream: TTColors.dressCream,
                                    warm: TTColors.dressWarm,
                                    done: _tieCompleted,
                                    playing: _phase == _DressPhase.tying,
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

class _DressVideoLayer extends StatelessWidget {
  const _DressVideoLayer({
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

class _StepBubble extends StatelessWidget {
  const _StepBubble({
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
