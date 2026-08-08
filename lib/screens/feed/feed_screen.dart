import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/rewards.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Feed Activity — tap floating food bubbles (max 9).
/// Same float + bubble feel as Drink Water. Idle Bao video behind.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedItem {
  const _FeedItem(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  static const _idleVideoAsset = 'assets/videos/bao_not_feeding.mp4';

  static const _foods = <_FeedItem>[
    _FeedItem('Milk', Icons.local_drink_rounded, Color(0xFFF5F5F5)),
    _FeedItem('Apple', Icons.apple, Color(0xFFE57373)),
    _FeedItem('Banana', Icons.breakfast_dining_rounded, Color(0xFFFFD54F)),
    _FeedItem('Rice', Icons.rice_bowl_rounded, Color(0xFFFFF8E1)),
    _FeedItem('Veggies', Icons.grass_rounded, Color(0xFF81C784)),
    _FeedItem('Soup', Icons.soup_kitchen_rounded, Color(0xFFFFB74D)),
    _FeedItem('Egg', Icons.egg_rounded, Color(0xFFFFF176)),
    _FeedItem('Bread', Icons.bakery_dining_rounded, Color(0xFFD7CCC8)),
    _FeedItem('Fruit', Icons.food_bank_rounded, Color(0xFFF48FB1)),
  ];

  late final AnimationController _float;
  final Set<int> _eaten = {};
  bool _celebrating = false;

  VideoPlayerController? _idleVideo;
  bool _idleReady = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    final idle = VideoPlayerController.asset(_idleVideoAsset);
    try {
      await idle.initialize();
      if (!mounted) {
        await idle.dispose();
        return;
      }
      await idle.setLooping(true);
      await idle.setVolume(0);
      await idle.play();
      setState(() {
        _idleVideo = idle;
        _idleReady = true;
      });
    } catch (_) {
      await idle.dispose();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _idleVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapFood(int index) async {
    if (_celebrating || _eaten.contains(index)) return;
    setState(() => _eaten.add(index));

    if (_eaten.length >= FeedRules.foodsForFullReward) {
      setState(() => _celebrating = true);
      final reward = FeedRules.rewardForFoods(_eaten.length);
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
    final remaining = FeedRules.maxFoods - _eaten.length;
    const bubbleSize = 84.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE0D0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE8DC),
                  TTColors.momoCoral,
                  Color(0xFFFFB090),
                ],
              ),
            ),
          ),
          _FeedVideoLayer(
            controller: _idleVideo,
            ready: _idleReady,
          ),
          // Soft top wash so status + title stay readable over the video.
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
                stars: 12 + (_eaten.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Text(
                'Feed Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so yummy!'
                    : 'Tap the yummy foods ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Same bob as Drink Water; two gentle arcs so all 9
                        // foods stay tappable without stacking.
                        return Stack(
                          children: List.generate(_foods.length, (i) {
                            final row = i < 5 ? 0 : 1;
                            final col = i < 5 ? i : i - 5;
                            final colsInRow = i < 5 ? 5 : 4;
                            final t = colsInRow <= 1
                                ? 0.5
                                : col / (colsInRow - 1);
                            final bob = math.sin(
                                    (_float.value + i * 0.25) * math.pi * 2) *
                                10;
                            final x = constraints.maxWidth *
                                    (0.10 + t * 0.80) -
                                (bubbleSize / 2);
                            final y = constraints.maxHeight *
                                    (0.14 + row * 0.34) +
                                math.sin(t * math.pi) * 18 +
                                bob;
                            final done = _eaten.contains(i);
                            final food = _foods[i];
                            return Positioned(
                              left: x,
                              top: y,
                              child: BounceButton(
                                onPressed:
                                    done ? null : () => _tapFood(i),
                                enabled: !done && !_celebrating,
                                semanticLabel: food.label,
                                child: FoodBubble(
                                  label: food.label,
                                  icon: food.icon,
                                  accent: food.accent,
                                  eaten: done,
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
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}

/// Transparent glassy food bubble — same shape/float language as [WaterGlass].
class FoodBubble extends StatelessWidget {
  const FoodBubble({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.eaten,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool eaten;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(accent, TTColors.momoCoral, 0.35)!;

    return AnimatedScale(
      scale: eaten ? 1.08 : 1.0,
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
                  colors: eaten
                      ? [
                          Colors.white.withValues(alpha: 0.55),
                          tint.withValues(alpha: 0.35),
                          tint.withValues(alpha: 0.55),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.85),
                          tint.withValues(alpha: 0.22),
                          tint.withValues(alpha: 0.40),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.30),
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
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              right: _size * 0.20,
              bottom: _size * 0.24,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: eaten
                      ? TTColors.bambooDeep.withValues(alpha: 0.95)
                      : TTColors.darkBrown.withValues(alpha: 0.85),
                ),
                Text(
                  label,
                  style: TTTypography.caption(color: TTColors.darkBrown)
                      .copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (eaten)
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
