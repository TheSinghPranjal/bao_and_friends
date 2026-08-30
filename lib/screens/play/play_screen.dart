import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/play_games.dart';
import '../../models/rewards.dart';
import '../../services/schedule_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Play Activity — pick games from a bottom tray (5 per page).
/// Idle Bao video behind. Each game opens its own sub-activity.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  static const _idleVideoAsset =
      'assets/videos/play/play_screen_video.mp4';

  final Set<int> _played = {};
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

  Future<void> _tapGame(int index) async {
    if (_celebrating || _played.contains(index)) return;

    final game = PlayGames.all[index];
    final completed = await context.push<bool>('/play-game/${game.id}');
    if (!mounted || completed != true) return;
    setState(() => _played.add(index));
    await ScheduleStore.markCompleted(ActivityId.play);

    if (_played.length >= PlayRules.gamesForFullReward) {
      setState(() => _celebrating = true);
      final reward = PlayRules.rewardForGames(_played.length);
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
    final remaining = PlayRules.maxGames - _played.length;

    return Scaffold(
      backgroundColor: TTColors.goldenGlow,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF8E1),
                  TTColors.goldenGlow,
                  TTColors.golden,
                ],
              ),
            ),
          ),
          _PlayVideoLayer(
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
                stars: 12 + (_played.isEmpty ? 0 : 1),
                beans: 3,
                level: 2,
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Text(
                'Play with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                remaining == 0
                    ? 'All done — so much fun!'
                    : 'Pick a game ($remaining left)',
                style: TTTypography.subtitle(),
              ),
              const Spacer(),
              ItemTrayBar(
                enabled: !_celebrating,
                items: [
                  for (var i = 0; i < PlayGames.all.length; i++)
                    TrayItem(
                      label: PlayGames.all[i].label,
                      icon: PlayGames.all[i].icon,
                      accent: PlayGames.all[i].accent,
                      done: _played.contains(i),
                      onTap: () => _tapGame(i),
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

class _PlayVideoLayer extends StatelessWidget {
  const _PlayVideoLayer({
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
