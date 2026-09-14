import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/learn_topics.dart';
import '../../models/rewards.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Alphabet lesson — plays A–Z segment videos in order.
/// Tap Next (or wait for auto-advance) through each segment, then reward.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});


  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  int _index = 0;
  bool _celebrating = false;
  bool _advancing = false;
  bool _disposed = false;


  VideoPlayerController? _video;
  bool _ready = false;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    unawaited(_loadSegment(0));
  }




  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    try {
      controller.pause();
    } catch (_) {}
    await controller.dispose();
  }



  Future<void> _loadSegment(int index) async {
    final prev = _video;
    final prevListener = _listener;
    if (prevListener != null) {
      prev?.removeListener(prevListener);
    }
    _listener = null;

    // Detach previous controller from the tree before disposing it.
    if (mounted && !_disposed) {
      setState(() {
        _ready = false;
        _video = null;
        _index = index;
        _advancing = false;
      });
    } else {
      _ready = false;
      _video = null;
      _index = index;
      _advancing = false;
    }

    await _disposeController(prev);
    if (_disposed || !mounted) return;

    final next = VideoPlayerController.asset(AlphabetVideos.segments[index]);
    try {
      await next.initialize();
      if (!mounted || _disposed) {
        await _disposeController(next);
        return;
      }
      await next.setLooping(false);
      await next.setVolume(0);
      if (!mounted || _disposed) {
        await _disposeController(next);
        return;
      }
      await next.play();
      if (!mounted || _disposed) {
        await _disposeController(next);
        return;
      }

      _listener = () {
        final v = _video;
        if (v == null ||
            !identical(v, next) ||
            _celebrating ||
            _advancing ||
            _disposed ||
            !v.value.isInitialized) {
          return;
        }
        final duration = v.value.duration;
        if (duration <= Duration.zero) return;
        final nearEnd =
            v.value.position >= duration - const Duration(milliseconds: 120);
        if (nearEnd && !v.value.isPlaying) {
          unawaited(_advance());
        }
      };
      next.addListener(_listener!);

      setState(() {
        _video = next;
        _ready = true;
      });
    } catch (_) {
      await _disposeController(next);
    }
  }

  Future<void> _advance() async {
    if (_celebrating || _advancing || _disposed) return;
    _advancing = true;

    if (_index >= AlphabetVideos.segments.length - 1) {
      await _finish();
      return;
    }
    await _loadSegment(_index + 1);
  }

  Future<void> _finish() async {
    if (_celebrating || _disposed) return;
    setState(() => _celebrating = true);

    final reward = LearnAlphabetRules.rewardForComplete();
    await StarsStore.add(reward.stars);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _disposed) return;
    await _showReward(reward);
    if (!mounted || _disposed) return;
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
    _disposed = true;
    final listener = _listener;
    final video = _video;
    _listener = null;
    _video = null;
    _ready = false;
    if (listener != null) {
      video?.removeListener(listener);
    }
    _float.dispose();
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index >= AlphabetVideos.segments.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFBBDEFB),
                  Color(0xFF90CAF9),
                ],
              ),
            ),
          ),
          _AlphabetVideoLayer(controller: _video, ready: _ready),
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
                'Alphabet!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    final bob = math.sin(_float.value * math.pi * 2) * 10;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 48 + bob),
                        child: BounceButton(
                          onPressed: _celebrating || _advancing
                              ? null
                              : () => unawaited(_advance()),
                          enabled: !_celebrating && !_advancing,
                          semanticLabel: isLast ? 'Finish' : 'Next letters',
                          child: _AlphabetNextBubble(
                            label: isLast ? 'Done' : 'Next',
                            playing: _advancing,
                          ),
                        ),
                      ),
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

class _AlphabetVideoLayer extends StatelessWidget {
  const _AlphabetVideoLayer({
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

class _AlphabetNextBubble extends StatelessWidget {
  const _AlphabetNextBubble({
    required this.label,
    this.playing = false,
  });

  final String label;
  final bool playing;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: playing ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
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
                    TTColors.skySoft.withValues(alpha: 0.55),
                    TTColors.skyBlue.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TTColors.skyDeep.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  label == 'Done'
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  size: 32,
                  color: TTColors.skyDeep,
                ),
                Text(
                  label,
                  style: TTTypography.caption(color: TTColors.darkBrown),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
