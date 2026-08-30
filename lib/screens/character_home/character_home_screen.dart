import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/character.dart';
import '../../services/schedule_store.dart';
import '../../services/sleep_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/circular_timer_ring.dart';
import '../../widgets/status_bar.dart';

/// Character Home — looping bedroom video (Bao) + frosted bottom activity sheet.
class CharacterHomeScreen extends StatefulWidget {
  const CharacterHomeScreen({super.key, required this.characterId});

  final String characterId;

  @override
  State<CharacterHomeScreen> createState() => _CharacterHomeScreenState();
}

class _CharacterHomeScreenState extends State<CharacterHomeScreen>
    with WidgetsBindingObserver {
  static const _baoAwakeVideoAsset =
      'assets/videos/bao_character_screen_bg_video_list/bao_character_screen_bg_video.mp4';
  static const _baoSleepingVideoAsset =
      'assets/videos/wake/bao_sleeping_video.mp4';

  /// Order matches the design mock: Learn · Play · Feed · Chores · Drink · Wake Up
  static const _navItems = <_NavItem>[
    _NavItem('Learn', Icons.menu_book_rounded, '/learn'),
    _NavItem('Play', Icons.sports_esports_rounded, '/play'),
    _NavItem('Feed', Icons.restaurant_rounded, '/feed'),
    _NavItem('Chores', Icons.wb_sunny_rounded, '/chores'),
    _NavItem('Drink', Icons.water_drop_rounded, '/drink'),
    _NavItem('Wake Up', Icons.wb_twilight_rounded, '/wake-up'),
  ];

  late FamilyCharacter character;
  int stars = 12;

  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _isSleeping = false;
  bool _sleepLoaded = false;
  Timer? _sleepCheckTimer;
  Map<String, ActivityTimerStatus> _timerByRoute = {};

  /// Visual selection in the bottom sheet (matches mock white-circle + orange).
  String? _selectedRoute;

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

    // Resolve real sleep state first (do not force-sleep outside windows).
    unawaited(_refreshSleepState(initVideo: true));
    unawaited(_refreshTimers());
    unawaited(_loadStars());
    _sleepCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        unawaited(_refreshSleepState());
        unawaited(_refreshTimers());
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSleepState());
      unawaited(_refreshTimers());
    }
  }

  Future<void> _loadStars() async {
    final total = await StarsStore.total();
    if (!mounted) return;
    setState(() => stars = total);
  }

  Future<void> _refreshTimers() async {
    final map = await ScheduleStore.homeStatuses();
    final wake = await SleepStore.wakeTimerStatus();
    if (!mounted) return;
    setState(() {
      _timerByRoute = {
        ...map,
        '/wake-up': wake,
      };
    });
  }

  Future<void> _refreshSleepState({bool initVideo = false}) async {
    final sleeping = await SleepStore.isSleeping();
    if (!mounted) return;

    setState(() {
      _isSleeping = sleeping;
      _sleepLoaded = true;
      // Emphasize Wake Up when Bao is asleep (same selected treatment as mock).
      if (sleeping) {
        _selectedRoute = '/wake-up';
      } else if (_selectedRoute == '/wake-up') {
        _selectedRoute = null;
      }
    });

    if (_isBao && (initVideo || sleeping != _videoShowsSleeping)) {
      await _initVideo(sleeping: sleeping);
    }
  }

  bool get _videoShowsSleeping {
    final src = _video?.dataSource ?? '';
    return src.contains('bao_sleeping_video');
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
    final video = _video;
    _video = null;
    _videoReady = false;
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  Future<void> _openNav(_NavItem item) async {
    setState(() => _selectedRoute = item.route);

    if (item.route == '/wake-up') {
      if (!_isSleeping) {
        if (!mounted) return;
        final canRest = await SleepStore.canReturnToSleep();
        if (!mounted) return;
        if (canRest) {
          await SleepStore.goBackToSleep();
          if (!mounted) return;
          await _refreshSleepState();
          await _refreshTimers();
          return;
        }
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
        '${item.route}?character=${character.id.name}',
      );
      if (!mounted) return;
      if (woke == true) {
        await _refreshSleepState();
        await _refreshTimers();
      }
      return;
    }

    await context.push('${item.route}?character=${character.id.name}');
    if (!mounted) return;
    await _refreshTimers();
    await _loadStars();
    // Restore sleep-based selection when returning home.
    setState(() {
      _selectedRoute = _isSleeping ? '/wake-up' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final comingSoon = !character.isUnlocked;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

          Column(
            children: [
              TinyStatusBar(
                stars: stars,
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
                    'Bao is sleeping — tap to wake up!',
                    style: TTTypography.subtitle(color: TTColors.darkBrown),
                  ),
                ),
              Expanded(
                child: !_isBao
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                  ? const Center(child: BaoFace(size: 110))
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
                            Text(character.name, style: TTTypography.title()),
                            Text(
                              'Ready to play!',
                              style: TTTypography.subtitle(),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.expand(),
              ),

              // ---- FROSTED BOTTOM ACTIVITY SHEET ----
              if (!comingSoon)
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + bottomInset),
                  child: _ActivityBottomSheet(
                    items: _navItems,
                    selectedRoute: _selectedRoute,
                    wakeUpDimmed: !_isSleeping,
                    timers: _timerByRoute,
                    onTap: (item) => unawaited(_openNav(item)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// Frosted glass bottom sheet — matches the design mock.
class _ActivityBottomSheet extends StatelessWidget {
  const _ActivityBottomSheet({
    required this.items,
    required this.selectedRoute,
    required this.wakeUpDimmed,
    required this.timers,
    required this.onTap,
  });

  final List<_NavItem> items;
  final String? selectedRoute;
  final bool wakeUpDimmed;
  final Map<String, ActivityTimerStatus> timers;
  final ValueChanged<_NavItem> onTap;

  static const _handle = Color(0xFFB0B0B0);

  Color _accentFor(String route) => switch (route) {
        '/learn' => TTColors.skyBlue,
        '/play' => TTColors.golden,
        '/feed' => TTColors.momoCoral,
        '/chores' => TTColors.bamboo,
        '/drink' => TTColors.waterDrop,
        '/wake-up' => TTColors.bedWarm,
        _ => TTColors.softBrown,
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: TTColors.darkBrown.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _handle.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: _SheetNavButton(
                        item: item,
                        selected: selectedRoute == item.route,
                        dimmed: item.route == '/wake-up' && wakeUpDimmed,
                        timer: timers[item.route],
                        accent: _accentFor(item.route),
                        onTap: () => onTap(item),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetNavButton extends StatelessWidget {
  const _SheetNavButton({
    required this.item,
    required this.selected,
    required this.dimmed,
    required this.timer,
    required this.accent,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool dimmed;
  final ActivityTimerStatus? timer;
  final Color accent;
  final VoidCallback onTap;

  static const _selectedLabel = Color(0xFFC4783A);
  static const _inactive = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    final due = timer?.isDue ?? false;
    final progress = timer?.progress ?? 1.0;
    final emphasize = selected || due;
    final labelColor = emphasize ? _selectedLabel : _inactive;

    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: BounceButton(
        onPressed: onTap,
        semanticLabel: item.label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emphasize ? Colors.white : Colors.transparent,
                boxShadow: emphasize
                    ? [
                        BoxShadow(
                          color: (due ? accent : TTColors.darkBrown)
                              .withValues(alpha: due ? 0.35 : 0.10),
                          blurRadius: due ? 10 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: CircularTimerRing(
                progress: progress,
                isDue: due && item.route != '/learn',
                color: accent,
                size: 46,
                child: Icon(item.icon, color: _inactive, size: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TTTypography.caption(color: labelColor).copyWith(
                fontSize: 11,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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

    return const ColoredBox(color: TTColors.peachSoft);
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
