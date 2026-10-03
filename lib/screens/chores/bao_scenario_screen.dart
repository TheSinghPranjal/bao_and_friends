import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/bao_scenarios.dart';
import '../../models/rewards.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Multi-step Bao scenario (Drawing Time, Rainy Day Routine).
///
/// Each step shows a looping muted idle clip. A tap plays that step's muted
/// action clip (also looping), then advances. After the last step, stars are
/// stored and [RewardPopup] shows before returning to the previous screen.
///
/// Opened from the Chores tray. Chores itself is behind the home premium tap
/// gate, same as Make Bed and the other chores.
///
/// Missing mp4s do not crash: the gradient stays up and [BaoFace] stands in.
class BaoScenarioScreen extends StatefulWidget {
  const BaoScenarioScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  State<BaoScenarioScreen> createState() => _BaoScenarioScreenState();
}

class _BaoScenarioScreenState extends State<BaoScenarioScreen>
    with SingleTickerProviderStateMixin {
  static const _stepButtonKey = Key('scenario-step-button');

  late final AnimationController _float;
  BaoScenario? _scenario;
  int _index = 0;
  bool _busy = false;
  bool _celebrating = false;
  bool _disposed = false;
  int _idleGen = 0;

  VideoPlayerController? _idle;
  VideoPlayerController? _action;
  bool _idleReady = false;
  bool _actionReady = false;

  @override
  void initState() {
    super.initState();
    _scenario = BaoScenarios.byId(widget.scenarioId);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    if (_scenario != null) {
      unawaited(_loadIdle());
    }
  }

  Future<bool> _assetReady(String asset) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(asset);
    } catch (_) {
      // Manifest unavailable — try the player and let a failed init fall back.
      return true;
    }
  }

  Future<void> _disposeQuiet(VideoPlayerController? controller) async {
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _loadIdle() async {
    final scenario = _scenario;
    if (scenario == null) return;
    final gen = ++_idleGen;
    final asset = scenario.steps[_index].idleVideoAsset;

    final previous = _idle;
    _idle = null;
    _idleReady = false;
    if (mounted && !_disposed) {
      setState(() {});
    }
    await _disposeQuiet(previous);
    if (gen != _idleGen || _disposed || !mounted) return;

    if (!await _assetReady(asset)) return;
    if (gen != _idleGen || _disposed || !mounted) return;

    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      if (gen != _idleGen ||
          _disposed ||
          !mounted ||
          controller.value.hasError) {
        await _disposeQuiet(controller);
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (gen != _idleGen || _disposed || !mounted) {
        await _disposeQuiet(controller);
        return;
      }
      setState(() {
        _idle = controller;
        _idleReady = true;
      });
    } catch (_) {
      await _disposeQuiet(controller);
    }
  }

  Future<void> _playAction(String asset) async {
    if (!await _assetReady(asset)) return;
    if (_disposed || !mounted) return;

    final action = VideoPlayerController.asset(asset);
    try {
      await action.initialize();
      if (_disposed || !mounted || action.value.hasError) {
        await _disposeQuiet(action);
        return;
      }
      await action.setLooping(true);
      await action.setVolume(0);
      await action.play();
      if (_disposed || !mounted) {
        await _disposeQuiet(action);
        return;
      }
      setState(() {
        _action = action;
        _actionReady = true;
      });

      var wait = action.value.duration;
      if (wait < const Duration(milliseconds: 400)) {
        wait = const Duration(milliseconds: 900);
      } else if (wait > const Duration(seconds: 20)) {
        wait = const Duration(seconds: 20);
      }
      await Future<void>.delayed(wait);
    } catch (_) {
      if (identical(_action, action)) {
        _action = null;
        _actionReady = false;
      }
      await _disposeQuiet(action);
      return;
    }

    if (!identical(_action, action)) return;
    if (mounted && !_disposed) {
      setState(() {
        _action = null;
        _actionReady = false;
      });
    } else {
      _action = null;
      _actionReady = false;
    }
    await _disposeQuiet(action);
  }

  Future<void> _onTap() async {
    final scenario = _scenario;
    if (scenario == null || _busy || _celebrating) return;
    setState(() => _busy = true);

    await _playAction(scenario.steps[_index].actionVideoAsset);
    if (!mounted || _disposed) return;

    if (_index >= scenario.steps.length - 1) {
      await _finish(scenario);
      return;
    }

    setState(() {
      _index += 1;
      _busy = false;
    });
    await _loadIdle();
  }

  RewardResult _rewardFor(BaoScenario scenario) {
    return switch (scenario.id) {
      BaoScenarios.drawingTimeId => DrawingTimeRules.rewardForSteps(
          DrawingTimeRules.stepsForFullReward,
        ),
      BaoScenarios.rainyDayId => RainyDayRules.rewardForSteps(
          RainyDayRules.stepsForFullReward,
        ),
      _ => const RewardResult(
          stars: 3,
          magicBeans: 1,
          message: 'Amazing! Great job!',
        ),
    };
  }

  Future<void> _finish(BaoScenario scenario) async {
    if (_celebrating || _disposed) return;
    setState(() => _celebrating = true);

    final reward = _rewardFor(scenario);
    await StarsStore.add(reward.stars);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _disposed) return;
    await _showReward(reward);
    if (!mounted || _disposed) return;
    if (context.canPop()) {
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
  void dispose() {
    _disposed = true;
    _idleGen++;
    _float.dispose();
    final idle = _idle;
    final action = _action;
    _idle = null;
    _action = null;
    _idleReady = false;
    _actionReady = false;
    idle?.dispose();
    action?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenario;
    if (scenario == null) {
      return Scaffold(
        backgroundColor: TTColors.cream,
        body: Column(
          children: [
            TinyStatusBar(
              showCounters: true,
              onSettings: () => context.push('/parent-gate'),
              leading: TtBackButton(
                onPressed: () {
                  if (context.canPop()) context.pop(false);
                },
              ),
            ),
            const Spacer(),
            const BaoFace(size: 140),
            const SizedBox(height: 16),
            Text(
              'Let\'s try another activity!',
              style: TTTypography.headline(color: TTColors.darkBrown),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    final step = scenario.steps[_index];
    final showVideo = (_idleReady && _idle != null) ||
        (_actionReady && _action != null);

    return Scaffold(
      backgroundColor: scenario.gradient.first,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: scenario.gradient,
              ),
            ),
          ),
          _ScenarioVideoLayer(controller: _idle, ready: _idleReady),
          _ScenarioVideoLayer(controller: _action, ready: _actionReady),
          if (!showVideo)
            const Center(
              child: BaoFace(
                key: Key('scenario-video-fallback'),
                size: 180,
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
                leading: TtBackButton(
                  onPressed: () {
                    if (context.canPop()) context.pop(false);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${scenario.title}!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TTTypography.title(color: TTColors.darkBrown).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
                child: Text(
                  step.detail,
                  textAlign: TextAlign.center,
                  style: TTTypography.body(color: TTColors.softBrown),
                ),
              ),
              Text(
                '${_index + 1} / ${scenario.steps.length}',
                style: TTTypography.caption(color: TTColors.softBrown),
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
                          key: _stepButtonKey,
                          onPressed: _busy || _celebrating
                              ? null
                              : () => unawaited(_onTap()),
                          enabled: !_busy && !_celebrating,
                          semanticLabel: 'Play ${step.label}',
                          child: _ScenarioStepBubble(
                            icon: step.icon,
                            accent: scenario.trayAccent,
                            playing: _busy,
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

class _ScenarioVideoLayer extends StatelessWidget {
  const _ScenarioVideoLayer({
    required this.controller,
    required this.ready,
  });

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (!ready || c == null || !c.value.isInitialized || c.value.hasError) {
      return const SizedBox.expand();
    }

    final size = c.value.size;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width > 0 ? size.width : 393,
          height: size.height > 0 ? size.height : 852,
          child: VideoPlayer(
            key: ValueKey(c),
            c,
          ),
        ),
      ),
    );
  }
}

class _ScenarioStepBubble extends StatelessWidget {
  const _ScenarioStepBubble({
    required this.icon,
    required this.accent,
    required this.playing,
  });

  final IconData icon;
  final Color accent;
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.0,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                accent.withValues(alpha: 0.45),
                accent.withValues(alpha: 0.85),
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
            ],
          ),
          child: Icon(icon, size: 40, color: TTColors.darkBrown),
        ),
      ),
    );
  }
}
