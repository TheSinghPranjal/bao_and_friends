import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/rewards.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Feed Activity — pick foods from a bottom tray (5 per page).
/// Idle Bao video behind.
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

class _FeedScreenState extends State<FeedScreen> {
  static const _idleVideoAsset = 'assets/videos/bao_not_feeding.mp4';

  static const _foods = <_FeedItem>[
    _FeedItem('Milk', Icons.local_drink_rounded, Color(0xFFF5F5F5)),
    _FeedItem('Apple', Icons.apple, Color(0xFFE57373)),
    _FeedItem('Banana', Icons.breakfast_dining_rounded, Color(0xFFFFD54F)),
    _FeedItem('Rice', Icons.rice_bowl_rounded, Color(0xFFFFF8E1)),
    _FeedItem('Veggies', Icons.grass_rounded, Color(0xFF81C784)),
    _FeedItem('Soup', Icons.soup_kitchen_rounded, Color(0xFFFFB74D)),
    _FeedItem('Egg', Icons.egg_rounded, Color(0xFFFFF176)),
    _FeedItem('Sandwich', Icons.lunch_dining_rounded, Color(0xFFE6B87A)),
    _FeedItem('Bread', Icons.bakery_dining_rounded, Color(0xFFD7CCC8)),
    _FeedItem('Fruit', Icons.food_bank_rounded, Color(0xFFF48FB1)),
  ];

  final Set<int> _eaten = {};
  bool _celebrating = false;

  VideoPlayerController? _idleVideo;
  bool _idleReady = false;

  @override
  void initState() {
    super.initState();
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
      if (!mounted) {
        await idle.dispose();
        return;
      }
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
    final video = _idleVideo;
    _idleVideo = null;
    _idleReady = false;
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  Future<void> _tapFood(int index) async {
    if (_celebrating || _eaten.contains(index)) return;

    // Milk / Apple / Banana / Veggies / Sandwich open their own activity screens.
    if (index == 0) {
      final completed = await context.push<bool>('/drink-milk');
      if (!mounted || completed != true) return;
      setState(() => _eaten.add(index));
    } else if (index == 1) {
      final completed = await context.push<bool>('/eat-apple');
      if (!mounted || completed != true) return;
      setState(() => _eaten.add(index));
    } else if (index == 2) {
      final completed = await context.push<bool>('/eat-banana');
      if (!mounted || completed != true) return;
      setState(() => _eaten.add(index));
    } else if (index == 4) {
      final completed = await context.push<bool>('/eat-veggies');
      if (!mounted || completed != true) return;
      setState(() => _eaten.add(index));
    } else if (index == 7) {
      final completed = await context.push<bool>('/eat-sandwich');
      if (!mounted || completed != true) return;
      setState(() => _eaten.add(index));
    } else {
      setState(() => _eaten.add(index));
    }

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
              const Spacer(),
              ItemTrayBar(
                enabled: !_celebrating,
                items: [
                  for (var i = 0; i < _foods.length; i++)
                    TrayItem(
                      label: _foods[i].label,
                      icon: _foods[i].icon,
                      accent: _foods[i].accent,
                      done: _eaten.contains(i),
                      onTap: () => _tapFood(i),
                    ),
                ],
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
