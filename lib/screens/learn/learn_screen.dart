import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/character_bg_videos.dart';
import '../../models/learn_topics.dart';
import '../../theme/tt_colors.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/item_tray_bar.dart';
import '../../widgets/rotating_headline.dart';
import '../../widgets/status_bar.dart';

/// Learn Activity — pick topics from a bottom tray (same pattern as Play / Chores).
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const _idleVideoAsset = CharacterBgVideos.fallback;

  final Set<String> _done = {};
  VideoPlayerController? _idleVideo;
  bool _idleReady = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    final idle = VideoPlayerController.asset(_idleVideoAsset);
    try {
      await idle.initialize();
      if (!mounted || _disposed) {
        await idle.dispose();
        return;
      }
      await idle.setLooping(true);
      await idle.setVolume(0);
      if (!mounted || _disposed) {
        await idle.dispose();
        return;
      }
      await idle.play();
      if (!mounted || _disposed) {
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
    _disposed = true;
    final video = _idleVideo;
    _idleVideo = null;
    _idleReady = false;
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  Future<void> _tapTopic(LearnTopicSpec topic) async {
    if (topic.hasActivity) {
      final completed = await context.push<bool>(topic.route!);
      if (!mounted) return;
      if (completed == true) {
        setState(() => _done.add(topic.id));
      }
      return;
    }

    await context.push(
      '/activity?title=${Uri.encodeComponent(topic.label)}&module=Learn',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TTColors.skySoft,
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
                  TTColors.skySoft,
                  TTColors.skyBlue,
                ],
              ),
            ),
          ),
          _LearnVideoLayer(
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: RotatingHeadline(
                  phrases: LearnHeadlinePhrases.all,
                ),
              ),
              const Spacer(),
              ItemTrayBar(
                items: [
                  for (final topic in LearnTopics.all)
                    TrayItem(
                      label: topic.label,
                      icon: topic.icon,
                      accent: topic.accent,
                      done: _done.contains(topic.id),
                      onTap: () => unawaited(_tapTopic(topic)),
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

class _LearnVideoLayer extends StatelessWidget {
  const _LearnVideoLayer({
    required this.controller,
    required this.ready,
  });

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (!ready || c == null || !c.value.isInitialized) {
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
