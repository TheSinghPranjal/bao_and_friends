import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/rewards.dart';
import '../../services/sleep_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Wake Up Activity — Bao is sleeping; tap the floating Wake Up bubble.
/// Sleeping video → waking video. Marks Bao awake for the next 1 hour.
class WakeUpScreen extends StatefulWidget {
  const WakeUpScreen({super.key});

  @override
  State<WakeUpScreen> createState() => _WakeUpScreenState();
}

class _WakeUpScreenState extends State<WakeUpScreen>
    with TickerProviderStateMixin {
  static const _sleepingVideoAsset = 'assets/videos/bao_sleeping.mp4';
  // Placeholder until a dedicated waking clip is added (same source for now).
  static const _wakingVideoAsset = 'assets/videos/bao_waking_up.mp4';
  static const _crossfadeDuration = Duration(milliseconds: 550);

  late final AnimationController _float;
  late final AnimationController _crossfade;
  bool _waking = false;
  bool _celebrating = false;
  bool _done = false;

  VideoPlayerController? _sleepingVideo;
  VideoPlayerController? _wakingVideo;
  bool _sleepingReady = false;
  bool _wakingReady = false;
  VoidCallback? _wakingListener;

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
    final sleeping = VideoPlayerController.asset(_sleepingVideoAsset);
    final waking = VideoPlayerController.asset(_wakingVideoAsset);

    try {
      await Future.wait([sleeping.initialize(), waking.initialize()]);
      if (!mounted) {
        await sleeping.dispose();
        await waking.dispose();
        return;
      }

      await sleeping.setLooping(true);
      await sleeping.setVolume(0);
      await waking.setLooping(false);
      await waking.setVolume(0);
      await sleeping.play();

      _wakingListener = () {
        final v = _wakingVideo;
        if (v == null || !_waking || !v.value.isInitialized) return;
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd = v.value.position >=
            duration - const Duration(milliseconds: 80);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_finishWake());
        }
      };
      waking.addListener(_wakingListener!);

      setState(() {
        _sleepingVideo = sleeping;
        _wakingVideo = waking;
        _sleepingReady = true;
        _wakingReady = true;
      });
    } catch (_) {
      await sleeping.dispose();
      await waking.dispose();
    }
  }

  Future<void> _playWakeAnimation() async {
    final waking = _wakingVideo;
    if (waking == null || !_wakingReady || _waking) return;

    setState(() => _waking = true);

    await waking.seekTo(Duration.zero);
    await waking.play();
    if (!mounted) return;

    await _crossfade.forward();
  }

  Future<void> _finishWake() async {
    if (!_waking || _done) return;
    _done = true;

    final waking = _wakingVideo;
    if (waking != null && waking.value.isInitialized) {
      await waking.setLooping(true);
      if (!waking.value.isPlaying) {
        await waking.seekTo(Duration.zero);
        await waking.play();
      }
    }

    await SleepStore.markWokeUp();
    if (!mounted) return;

    setState(() => _celebrating = true);
    final reward = WakeUpRules.reward;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await _showReward(reward);
    if (!mounted) return;
    context.pop(true);
  }

  @override
  void dispose() {
    final listener = _wakingListener;
    if (listener != null) {
      _wakingVideo?.removeListener(listener);
    }
    _float.dispose();
    _crossfade.dispose();
    _sleepingVideo?.dispose();
    _wakingVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapWakeBubble() async {
    if (_waking || _celebrating) return;
    unawaited(_playWakeAnimation());
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

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E6B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A2744),
                  Color(0xFF3D4F7A),
                  Color(0xFF6B7BA8),
                ],
              ),
            ),
          ),
          _WakeVideoLayer(
            controller: _sleepingVideo,
            ready: _sleepingReady,
          ),
          AnimatedBuilder(
            animation: _crossfade,
            builder: (context, child) {
              return Opacity(
                opacity: Curves.easeInOut.transform(_crossfade.value),
                child: child,
              );
            },
            child: _WakeVideoLayer(
              controller: _wakingVideo,
              ready: _wakingReady,
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
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
                stars: 12 + (_done ? 1 : 0),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop(false)),
              ),
              const SizedBox(height: 8),
              Text(
                _waking ? 'Good morning, Bao!' : 'Bao is sleeping…',
                style: TTTypography.headline(color: TTColors.creamWhite),
              ),
              Text(
                _waking
                    ? 'Yawn… stretching… awake!'
                    : 'Tap the Wake Up bubble',
                style: TTTypography.subtitle(color: TTColors.creamWhite),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bob =
                            math.sin(_float.value * math.pi * 2) * 12;
                        final x = constraints.maxWidth * 0.5 - bubbleSize / 2;
                        final y = constraints.maxHeight * 0.18 + bob;
                        return Stack(
                          children: [
                            Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed: _waking || _celebrating
                                    ? null
                                    : _tapWakeBubble,
                                enabled: !_waking && !_celebrating,
                                semanticLabel: 'Wake Up',
                                child: WakeUpBubble(
                                  active: _waking,
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

class _WakeVideoLayer extends StatelessWidget {
  const _WakeVideoLayer({
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
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}

/// Soft sunrise wake-up bubble.
class WakeUpBubble extends StatelessWidget {
  const WakeUpBubble({super.key, this.active = false});

  final bool active;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
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
                  colors: active
                      ? [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.goldenBright.withValues(alpha: 0.75),
                          TTColors.golden.withValues(alpha: 0.85),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          TTColors.goldenGlow.withValues(alpha: 0.55),
                          TTColors.golden.withValues(alpha: 0.70),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.golden.withValues(alpha: 0.40),
                    blurRadius: 18,
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded,
                  size: 34,
                  color: TTColors.darkBrown.withValues(alpha: 0.85),
                ),
                Text(
                  'Wake Up',
                  style: TTTypography.caption(color: TTColors.darkBrown)
                      .copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (active)
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
