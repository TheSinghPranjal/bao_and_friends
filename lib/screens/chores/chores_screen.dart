import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/character_bg_videos.dart';
import '../../models/rewards.dart';
import '../../services/schedule_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Chores Activity — pick chores from a bottom tray (5 per page).
/// Idle Bao video behind.
class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoreItem {
  const _ChoreItem(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

class _ChoresScreenState extends State<ChoresScreen> {
  // Temporary idle clip until a dedicated chores bedroom video is added.
  static const _idleVideoAsset = CharacterBgVideos.fallback;

  static const _chores = <_ChoreItem>[
    _ChoreItem('Make Bed', Icons.bed_rounded, Color(0xFFB39DDB)),
    _ChoreItem('Brush Teeth', Icons.clean_hands_rounded, Color(0xFF80DEEA)),
    _ChoreItem('Wash Face', Icons.water_drop_outlined, Color(0xFF90CAF9)),
    _ChoreItem('Bath', Icons.bathtub_rounded, Color(0xFF4DD0E1)),
    _ChoreItem('Comb Hair', Icons.content_cut_rounded, Color(0xFFFFCC80)),
    _ChoreItem('Get Dressed', Icons.checkroom_rounded, Color(0xFFF48FB1)),
    _ChoreItem('Wear Shoes', Icons.snowshoeing_rounded, Color(0xFFA5D6A7)),
    _ChoreItem('School', Icons.school_rounded, Color(0xFF81C784)),
  ];

  /// Schedule id per tray index (null = no due badge).
  static const _scheduleIds = <ActivityId?>[
    ActivityId.makeBed,
    ActivityId.brushTeeth,
    ActivityId.washFace,
    ActivityId.bath,
    ActivityId.combHair,
    ActivityId.getDressed,
    ActivityId.wearShoes,
    null, // school
  ];

  final Set<int> _done = {};
  bool _celebrating = false;
  Map<int, int> _dueByIndex = {};

  VideoPlayerController? _idleVideo;
  bool _idleReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initVideo());
    unawaited(_refreshDues());
  }

  Future<void> _refreshDues() async {
    final dues = <int, int>{};
    for (var i = 0; i < _scheduleIds.length; i++) {
      final id = _scheduleIds[i];
      dues[i] = id == null ? 0 : await ScheduleStore.dueCount(id);
    }
    if (!mounted) return;
    setState(() {
      _dueByIndex = dues;
    });
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
    _idleVideo?.dispose();
    super.dispose();
  }

  Future<void> _tapChore(int index) async {
    if (_celebrating) return;
    // Allow anytime — due-count chores can be reopened for more dues / bonus taps.

    if (index == 0) {
      final completed = await context.push<bool>('/make-bed');
      if (!mounted || completed != true) {
        await _refreshDues();
        return;
      }
      setState(() => _done.add(index));
    } else if (index == 1) {
      final completed = await context.push<bool>('/brush-teeth');
      if (!mounted || completed != true) {
        await _refreshDues();
        return;
      }
      setState(() => _done.add(index));
    } else if (index == 2) {
      final completed = await context.push<bool>('/wash-face');
      if (!mounted || completed != true) {
        await _refreshDues();
        return;
      }
      setState(() => _done.add(index));
    } else if (index == 3) {
      final completed = await context.push<bool>('/bath');
      if (!mounted || completed != true) {
        await _refreshDues();
        return;
      }
      setState(() => _done.add(index));
    } else if (index == 4) {
      final completed = await context.push<bool>('/comb-hair');
      if (!mounted || completed != true) {
        await _refreshDues();
        return;
      }
      setState(() => _done.add(index));
    } else if (index == 5) {
      if (_done.contains(index)) return;
      final completed = await context.push<bool>('/get-dressed');
      if (!mounted || completed != true) return;
      setState(() => _done.add(index));
      await ScheduleStore.markCompleted(ActivityId.getDressed);
    } else if (index == 6) {
      if (_done.contains(index)) return;
      final completed = await context.push<bool>('/wear-shoes');
      if (!mounted || completed != true) return;
      setState(() => _done.add(index));
      await ScheduleStore.markCompleted(ActivityId.wearShoes);
    } else {
      if (_done.contains(index)) return;
      setState(() => _done.add(index));
    }

    await _refreshDues();

    if (_done.length >= ChoresRules.choresForFullReward) {
      setState(() => _celebrating = true);
      final reward = ChoresRules.rewardForChores(_done.length);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await StarsStore.add(reward.stars);
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF1F8E9),
                  TTColors.bambooLight,
                  Color(0xFFC5E1A5),
                ],
              ),
            ),
          ),
          _ChoresVideoLayer(
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
                'Help Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
              ),
              const Spacer(),
              ItemTrayBar(
                enabled: !_celebrating,
                items: [
                  for (var i = 0; i < _chores.length; i++)
                    TrayItem(
                      label: _chores[i].label,
                      icon: _chores[i].icon,
                      accent: _chores[i].accent,
                      done: _done.contains(i),
                      badgeCount: _dueByIndex[i] ?? 0,
                      highlighted: (_dueByIndex[i] ?? 0) > 0,
                      onTap: () => _tapChore(i),
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

class _ChoresVideoLayer extends StatelessWidget {
  const _ChoresVideoLayer({
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
