import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/feed_foods.dart';
import '../../services/feed_due_store.dart';
import '../../services/schedule_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/status_bar.dart';

/// Feed Activity — pick foods from a bottom tray (Play-style due badges).
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const _idleVideoAsset = 'assets/videos/bao_not_feeding.mp4';

  VideoPlayerController? _idleVideo;
  bool _idleReady = false;
  Map<String, int> _dueByFood = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_initVideo());
    unawaited(_refresh());
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refresh()),
    );
  }

  Future<void> _refresh() async {
    final dues = <String, int>{};
    for (final food in FeedFoods.all) {
      dues[food.id] = await FeedDueStore.dueCount(food.id);
    }
    if (!mounted) return;
    setState(() => _dueByFood = dues);
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
    _refreshTimer?.cancel();
    final video = _idleVideo;
    _idleVideo = null;
    _idleReady = false;
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  Future<void> _tapFood(FeedFoodSpec food) async {
    final completed = await context.push<bool>('/eat-food/${food.id}');
    if (!mounted) return;
    if (completed == true) {
      await ScheduleStore.markCompleted(ActivityId.feed);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
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
                  Color(0xFFF5A88A),
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
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Text(
                'Feed Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              const Spacer(),
              ItemTrayBar(
                items: [
                  for (final food in FeedFoods.all)
                    TrayItem(
                      label: food.label,
                      icon: food.icon,
                      accent: food.accent,
                      done: false,
                      badgeCount: _dueByFood[food.id] ?? 0,
                      highlighted: (_dueByFood[food.id] ?? 0) > 0,
                      onTap: () => unawaited(_tapFood(food)),
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
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}
