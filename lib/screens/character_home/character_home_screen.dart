import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/character.dart';
import '../../services/sleep_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Character Home — looping bedroom video (Bao) + floating side activity bubbles.
class CharacterHomeScreen extends StatefulWidget {
  const CharacterHomeScreen({super.key, required this.characterId});

  final String characterId;

  @override
  State<CharacterHomeScreen> createState() => _CharacterHomeScreenState();
}

class _CharacterHomeScreenState extends State<CharacterHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _baoAwakeVideoAsset =
      'assets/videos/bao_character_screen_bg_video.mp4';
  static const _baoSleepingVideoAsset = 'assets/videos/bao_sleeping.mp4';

  late final AnimationController _float;
  late FamilyCharacter character;
  int stars = 12;
  int beans = 3;
  int level = 2;

  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _isSleeping = false;
  bool _sleepLoaded = false;
  Timer? _sleepCheckTimer;

  /// Left column then right column — keeps Bao (center of the video) clear.
  static const _leftBubbles = <_BubbleSpec>[
    _BubbleSpec('Learn', Icons.menu_book_rounded, TTColors.skyBlue, '/learn'),
    _BubbleSpec('Feed', Icons.restaurant_rounded, TTColors.momoCoral, '/feed'),
    _BubbleSpec(
      'Drink',
      Icons.water_drop_rounded,
      TTColors.waterBlue,
      '/drink',
    ),
  ];

  static const _rightBubbles = <_BubbleSpec>[
    _BubbleSpec('Play', Icons.sports_esports_rounded, TTColors.golden, '/play'),
    _BubbleSpec(
      'Chores',
      Icons.wb_sunny_rounded,
      TTColors.bambooLight,
      '/chores',
    ),
    _BubbleSpec(
      'Wake Up',
      Icons.wb_twilight_rounded,
      TTColors.goldenBright,
      '/wake-up',
    ),
  ];

  bool get _isBao => character.id == CharacterId.bao;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final id = CharacterId.values.firstWhere(
      (e) => e.name == widget.characterId,
      orElse: () => CharacterId.bao,
    );
    character = characterById(id);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    unawaited(_refreshSleepState(initVideo: true));
    _sleepCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshSleepState()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSleepState());
    }
  }

  Future<void> _refreshSleepState({bool initVideo = false}) async {
    final sleeping = await SleepStore.isSleeping();
    if (!mounted) return;

    final changed = sleeping != _isSleeping || !_sleepLoaded;
    setState(() {
      _isSleeping = sleeping;
      _sleepLoaded = true;
    });

    if (_isBao && (initVideo || (changed && sleeping != _videoShowsSleeping))) {
      await _initVideo(sleeping: sleeping);
    }
  }

  bool get _videoShowsSleeping {
    final src = _video?.dataSource ?? '';
    return src.contains('bao_sleeping');
  }

  Future<void> _initVideo({required bool sleeping}) async {
    final asset = sleeping ? _baoSleepingVideoAsset : _baoAwakeVideoAsset;
    final previous = _video;

    if (previous != null &&
        previous.value.isInitialized &&
        _videoShowsSleeping == sleeping) {
      return;
    }

    previous?.pause();

    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoReady = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous?.dispose();
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sleepCheckTimer?.cancel();
    _float.dispose();
    final video = _video;
    _video = null;
    _videoReady = false;
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  Future<void> _openBubble(_BubbleSpec b) async {
    if (b.route == '/wake-up') {
      if (!_isSleeping) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bao is already awake! Come back in a bit.',
              style: TTTypography.body(color: TTColors.creamWhite),
            ),
            backgroundColor: TTColors.darkBrown,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      final woke = await context.push<bool>(
        '${b.route}?character=${character.id.name}',
      );
      if (!mounted) return;
      if (woke == true) {
        await _refreshSleepState();
      }
      return;
    }

    context.push('${b.route}?character=${character.id.name}');
  }

  @override
  Widget build(BuildContext context) {
    final comingSoon = !character.isUnlocked;

    return Scaffold(
      backgroundColor: TTColors.peachSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- LOOPING BACKGROUND ----
          if (_isBao)
            _LoopingVideoBackground(
              controller: _video,
              ready: _videoReady,
            )
          else
            const _HomeBedroomBg(),

          // Soft edge vignette so bubbles stay readable
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TTColors.darkBrown.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.transparent,
                    TTColors.darkBrown.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.18, 0.82, 1.0],
                ),
              ),
            ),
          ),

          Column(
            children: [
              TinyStatusBar(
                stars: stars,
                beans: beans,
                level: level,
                onSettings: () => context.push('/parent-gate'),
                onProfile: () => context.push('/profile'),
                leading: TtBackButton(
                  onPressed: () => context.go('/select'),
                  semanticLabel: 'Back to family',
                ),
              ),
              if (comingSoon)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${character.name} is Coming Soon!',
                    style: TTTypography.headline(),
                  ),
                )
              else if (_isBao && _sleepLoaded && _isSleeping)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Bao is sleeping — tap Wake Up!',
                    style: TTTypography.subtitle(color: TTColors.darkBrown),
                  ),
                ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final t = _float.value;

                        return Stack(
                          children: [
                            // ---- LEFT SIDE BUBBLES ----
                            for (var i = 0; i < _leftBubbles.length; i++)
                              _SideBubble(
                                spec: _leftBubbles[i],
                                side: _BubbleSide.left,
                                index: i,
                                count: _leftBubbles.length,
                                screenSize: Size(w, h),
                                t: t,
                                emphasized: false,
                                dimmed: false,
                                onTap: () => unawaited(
                                  _openBubble(_leftBubbles[i]),
                                ),
                              ),

                            // ---- RIGHT SIDE BUBBLES ----
                            for (var i = 0; i < _rightBubbles.length; i++)
                              _SideBubble(
                                spec: _rightBubbles[i],
                                side: _BubbleSide.right,
                                index: i,
                                count: _rightBubbles.length,
                                screenSize: Size(w, h),
                                t: t,
                                emphasized: _rightBubbles[i].route ==
                                        '/wake-up' &&
                                    _isSleeping,
                                dimmed: _rightBubbles[i].route ==
                                        '/wake-up' &&
                                    !_isSleeping,
                                onTap: () => unawaited(
                                  _openBubble(_rightBubbles[i]),
                                ),
                              ),

                            // For non-Bao characters (no video yet), keep a
                            // gentle center-stage portrait so the room isn't empty.
                            if (!_isBao)
                              Positioned(
                                left: w / 2 - 70,
                                top: h * 0.42,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(character.cardColorValue)
                                            .withValues(alpha: 0.35),
                                        boxShadow: TTShadows.glow(
                                          Color(character.cardColorValue),
                                        ),
                                      ),
                                      child: character.id == CharacterId.poko
                                          ? const Center(
                                              child: BaoFace(size: 110),
                                            )
                                          : Center(
                                              child: Text(
                                                character.name[0],
                                                style: TTTypography.displayHero(
                                                  color: TTColors.darkBrown,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      character.name,
                                      style: TTTypography.title(),
                                    ),
                                    Text(
                                      'Ready to play!',
                                      style: TTTypography.subtitle(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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

class _LoopingVideoBackground extends StatelessWidget {
  const _LoopingVideoBackground({
    required this.controller,
    required this.ready,
  });

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    if (ready && controller != null && controller!.value.isInitialized) {
      final size = controller!.value.size;
      return ColoredBox(
        color: TTColors.peachSoft,
        child: SizedBox.expand(
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
        ),
      );
    }

    // Soft peach while the video initializes
    return const ColoredBox(color: TTColors.peachSoft);
  }
}

class _BubbleSpec {
  const _BubbleSpec(this.label, this.icon, this.color, this.route);
  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

enum _BubbleSide { left, right }

/// Floating activity bubble anchored to the left or right side of the screen.
class _SideBubble extends StatelessWidget {
  const _SideBubble({
    required this.spec,
    required this.side,
    required this.index,
    required this.count,
    required this.screenSize,
    required this.t,
    required this.onTap,
    this.emphasized = false,
    this.dimmed = false,
  });

  final _BubbleSpec spec;
  final _BubbleSide side;
  final int index;
  final int count;
  final Size screenSize;
  final double t;
  final VoidCallback onTap;
  final bool emphasized;
  final bool dimmed;

  static const double _bubbleSize = 92;

  @override
  Widget build(BuildContext context) {
    // Vertical band in the middle of the screen, evenly spaced.
    final topPad = screenSize.height * 0.18;
    final bottomPad = screenSize.height * 0.14;
    final usable = screenSize.height - topPad - bottomPad;
    final step = usable / (count + 1);
    final bob = math.sin((t + index * 0.28) * math.pi * 2) * 8;
    final y = topPad + step * (index + 1) - _bubbleSize / 2 + bob;

    final edgePad = math.max(12.0, screenSize.width * 0.04);
    final x = side == _BubbleSide.left
        ? edgePad
        : screenSize.width - edgePad - _bubbleSize;

    final scale = emphasized ? 1.08 : 1.0;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1.0,
        child: Transform.scale(
          scale: scale,
          child: BounceButton(
            onPressed: onTap,
            semanticLabel: spec.label,
            child: Container(
              width: _bubbleSize,
              height: _bubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spec.color,
                border: Border.all(
                  color: emphasized ? TTColors.golden : TTColors.creamWhite,
                  width: emphasized ? 5 : 4,
                ),
                boxShadow: emphasized
                    ? TTShadows.glow(TTColors.golden)
                    : TTShadows.soft,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(spec.icon, color: TTColors.darkBrown, size: 30),
                  const SizedBox(height: 2),
                  Text(
                    spec.label,
                    style: TTTypography.caption(color: TTColors.darkBrown)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBedroomBg extends StatelessWidget {
  const _HomeBedroomBg();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TTColors.peachSoft,
            TTColors.peachWall,
            Color(0xFFE8C4A8),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _HomeRoomPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HomeRoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.12,
        size.width * 0.32,
        size.height * 0.22,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(win, Paint()..color = TTColors.skySoft);
    canvas.drawRRect(
      win,
      Paint()
        ..color = TTColors.creamWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFFD4A574).withValues(alpha: 0.55),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.55,
        height: 48,
      ),
      Paint()..color = TTColors.baoBlue.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
