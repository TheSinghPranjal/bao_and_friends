import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/play_games.dart';
import '../../services/play_due_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/status_bar.dart';

/// Play Activity — pick games from a bottom tray.
/// Due games glow + show a badge of missed slots for today.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  static const _idleVideoAsset = 'assets/videos/play/play_screen_video.mp4';

  VideoPlayerController? _idleVideo;
  bool _idleReady = false;
  Map<String, int> _dueByGame = {};
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
    for (final game in PlayGames.all) {
      dues[game.id] = await PlayDueStore.dueCount(game.id);
    }
    if (!mounted) return;
    setState(() {
      _dueByGame = dues;
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

  Future<void> _tapGame(int index) async {
    final game = PlayGames.all[index];
    await context.push<bool>('/play-game/${game.id}');
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final anyDue = _dueByGame.values.any((c) => c > 0);

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
                onSettings: () => context.push('/parent-gate'),
                leading: TtBackButton(onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Text(
                'Play with Bao!',
                style: TTTypography.headline(color: TTColors.darkBrown),
              ),
              Text(
                anyDue
                    ? 'Something is due — tap a glowing game!'
                    : 'Pick a game anytime for bonus stars',
                style: TTTypography.subtitle(),
              ),
              const Spacer(),
              ItemTrayBar(
                items: [
                  for (final game in PlayGames.all)
                    TrayItem(
                      label: game.label,
                      icon: game.icon,
                      accent: game.accent,
                      done: false,
                      badgeCount: _dueByGame[game.id] ?? 0,
                      highlighted: (_dueByGame[game.id] ?? 0) > 0,
                      onTap: () => unawaited(
                        _tapGame(PlayGames.all.indexOf(game)),
                      ),
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
