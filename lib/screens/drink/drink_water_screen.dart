import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/rewards.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Drink Water Activity — tap floating glasses (max 4).
/// 1 glass → 1 star. All 4 → 3 stars + 1 Magic Bean. Timer resets 4h.
class DrinkWaterScreen extends StatefulWidget {
  const DrinkWaterScreen({super.key});

  @override
  State<DrinkWaterScreen> createState() => _DrinkWaterScreenState();
}

class _DrinkWaterScreenState extends State<DrinkWaterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  final Set<int> _drunk = {};
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _tapGlass(int index) async {
    if (_celebrating || _drunk.contains(index)) return;
    setState(() => _drunk.add(index));

    if (_drunk.length >= DrinkWaterRules.glassesForFullReward) {
      setState(() => _celebrating = true);
      final reward = DrinkWaterRules.rewardForGlasses(_drunk.length);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _showReward(reward);
      if (!mounted) return;
      context.pop();
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
    final remaining =
        DrinkWaterRules.maxGlasses - _drunk.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB8E8F8),
                  TTColors.waterBlue,
                  Color(0xFF6EC6E8),
                ],
              ),
            ),
          ),
          Column(
            children: [
              TinyStatusBar(
                showCounters: true,
                stars: 12 + (_drunk.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: BounceButton(
                  onPressed: () => context.pop(),
                  semanticLabel: 'Back',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TTColors.creamWhite,
                      boxShadow: TTShadows.soft,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: TTColors.darkBrown,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sip with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so refreshing!'
                    : 'Tap the happy glasses ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              const SizedBox(height: 12),
              const BaoFace(size: 96),
              Text('Bao is waiting happily!', style: TTTypography.caption()),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: List.generate(DrinkWaterRules.maxGlasses,
                              (i) {
                            final angle = (i / DrinkWaterRules.maxGlasses) *
                                    math.pi *
                                    1.2 -
                                0.3;
                            final bob = math.sin(
                                    (_float.value + i * 0.25) * math.pi * 2) *
                                10;
                            final x = constraints.maxWidth * 0.5 +
                                math.cos(angle) * constraints.maxWidth * 0.32 -
                                40;
                            final y = constraints.maxHeight * 0.35 +
                                math.sin(angle) * 80 +
                                bob;
                            final done = _drunk.contains(i);
                            return Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed:
                                    done ? null : () => _tapGlass(i),
                                enabled: !done,
                                semanticLabel: 'Water glass ${i + 1}',
                                child: WaterGlass(
                                  drunk: done,
                                  playing: done,
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

class WaterGlass extends StatelessWidget {
  const WaterGlass({super.key, required this.drunk, this.playing = false});

  final bool drunk;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: drunk
            ? TTColors.bambooLight.withValues(alpha: 0.85)
            : TTColors.creamWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: drunk ? TTColors.bamboo : TTColors.waterDrop,
          width: 3,
        ),
        boxShadow: TTShadows.soft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            drunk ? Icons.check_circle_rounded : Icons.water_drop_rounded,
            size: 36,
            color: drunk ? TTColors.bambooDeep : TTColors.waterDrop,
          ),
          const SizedBox(height: 4),
          Text(
            drunk ? 'Yum!' : 'Sip!',
            style: TTTypography.caption(color: TTColors.darkBrown),
          ),
          if (playing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'drink loop – placeholder',
                textAlign: TextAlign.center,
                style: TTTypography.caption(
                  color: TTColors.softBrown.withValues(alpha: 0.7),
                ).copyWith(fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class RewardPopup extends StatelessWidget {
  const RewardPopup({
    super.key,
    required this.reward,
    required this.onContinue,
  });

  final RewardResult reward;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
        boxShadow: TTShadows.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Wonderful!', style: TTTypography.headline()),
          const SizedBox(height: 8),
          Text(
            reward.message,
            textAlign: TextAlign.center,
            style: TTTypography.body(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (reward.stars > 0) ...[
                const Icon(Icons.star_rounded, color: TTColors.golden, size: 36),
                Text(
                  '+${reward.stars}',
                  style: TTTypography.title(),
                ),
                const SizedBox(width: 16),
              ],
              if (reward.magicBeans > 0) ...[
                const Icon(Icons.eco_rounded, color: TTColors.bamboo, size: 36),
                Text(
                  '+${reward.magicBeans}',
                  style: TTTypography.title(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stars & Magic Beans burst – placeholder',
            style: TTTypography.caption(),
          ),
          const SizedBox(height: 20),
          BounceButton(
            onPressed: onContinue,
            child: Container(
              constraints: const BoxConstraints(minWidth: 160, minHeight: 56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TTColors.golden,
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
              ),
              child: Text('Yay!', style: TTTypography.button()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cute water-drop reminder (every 4 hours).
class DrinkWaterReminderPopup extends StatelessWidget {
  const DrinkWaterReminderPopup({
    super.key,
    required this.onTap,
    required this.onDismiss,
  });

  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
        boxShadow: TTShadows.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: TTColors.waterBlue,
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 44,
              color: TTColors.creamWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text('Time for a sip!', style: TTTypography.title()),
          Text(
            'Bao would love some water with you.',
            textAlign: TextAlign.center,
            style: TTTypography.body(),
          ),
          const SizedBox(height: 16),
          BounceButton(
            onPressed: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 180, minHeight: 56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TTColors.waterDrop,
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
              ),
              child: Text(
                'Let\'s Drink!',
                style: TTTypography.button(color: TTColors.creamWhite),
              ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text('Maybe later', style: TTTypography.caption()),
          ),
        ],
      ),
    );
  }
}
