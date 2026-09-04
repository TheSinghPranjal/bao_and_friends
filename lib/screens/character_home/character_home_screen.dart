import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_schedule.dart';
import '../../models/character.dart';
import '../../models/character_bg_videos.dart';
import '../../services/premium_store.dart';
import '../../services/schedule_store.dart';
import '../../services/sleep_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/premium_dialogs.dart';
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

  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _isSleeping = false;
  bool _sleepLoaded = false;
  Timer? _sleepCheckTimer;
  Map<String, ActivityTimerStatus> _timerByRoute = {};
  /// Tracks period or special clip key so we swap when a window starts/ends.
  String? _awakeClipKey;

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
    unawaited(StarsStore.total());
    _sleepCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
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

  Future<void> _refreshTimers() async {
    final map = await ScheduleStore.homeStatuses();
    final wake = await SleepStore.wakeTimerStatus();
    if (!mounted) return;
    setState(() {
      _timerByRoute = {
        ...map,
        '/wake-up': wake,
      };
      // Drop selection highlight unless that route is actually due (or wake while asleep).
      final selected = _selectedRoute;
      if (selected != null && selected != '/wake-up') {
        final status = _timerByRoute[selected];
        if (status == null || !status.isDue) {
          _selectedRoute = null;
        }
      }
    });
  }

  Future<void> _refreshSleepState({bool initVideo = false}) async {
    final sleeping = await SleepStore.isSleeping();
    if (!mounted) return;

    // Special daytime clips override sleep video when active.
    final special = CharacterBgVideos.specialFor();
    final nightAwake =
        !sleeping && await SleepStore.inNightSleepWindow();
    final clipKey = special != null
        ? 'special:${special.id}'
        : sleeping
            ? 'sleep'
            : (nightAwake
                ? 'night_awake_fallback'
                : CharacterBgVideos.awakeKeyFor());
    final clipChanged = clipKey != _awakeClipKey;

    setState(() {
      _isSleeping = sleeping;
      _sleepLoaded = true;
      _awakeClipKey = clipKey;
      if (sleeping && special == null) {
        _selectedRoute = '/wake-up';
      } else if (_selectedRoute == '/wake-up' && !sleeping) {
        _selectedRoute = null;
      }
    });

    if (_isBao &&
        (initVideo ||
            sleeping != _videoShowsSleeping ||
            clipChanged ||
            (special != null &&
                !_currentAwakeAsset
                    .contains(special.asset.split('/').last)))) {
      await _initVideo(sleeping: sleeping);
    }
  }

  bool get _videoShowsSleeping {
    final src = _video?.dataSource ?? '';
    return src.contains('bao_sleeping_video');
  }

  String get _currentAwakeAsset {
    final src = _video?.dataSource ?? '';
    for (final asset in [
      ...CharacterBgVideos.allSpecialAssets,
      ...CharacterBgVideos.allPeriodAssets,
      CharacterBgVideos.fallback,
    ]) {
      if (src.contains(asset.split('/').last)) return asset;
    }
    return '';
  }

  Future<void> _initVideo({required bool sleeping}) async {
    final special = CharacterBgVideos.specialFor();
    final nightAwake =
        !sleeping && await SleepStore.inNightSleepWindow();

    // Priority: special → sleep → night-wake fallback → period default.
    final String preferred;
    if (special != null) {
      preferred = special.asset;
    } else if (sleeping) {
      preferred = _baoSleepingVideoAsset;
    } else if (nightAwake) {
      // After a night wake (10pm–6am), show the generic bedroom clip.
      preferred = CharacterBgVideos.fallback;
    } else {
      preferred = CharacterBgVideos.assetForNow();
    }

    final previous = _video;

    _awakeClipKey = special != null
        ? 'special:${special.id}'
        : sleeping
            ? 'sleep'
            : (nightAwake
                ? 'night_awake_fallback'
                : CharacterBgVideos.awakeKeyFor());

    final alreadyCorrect = previous != null &&
        previous.value.isInitialized &&
        previous.dataSource.contains(preferred.split('/').last);
    if (alreadyCorrect) return;

    previous?.pause();

    final loaded = await _tryLoadAsset(preferred) ??
        (special != null || !sleeping
            ? await _tryLoadAsset(CharacterBgVideos.fallback)
            : null);

    if (loaded == null) return;

    if (!mounted) {
      await loaded.dispose();
      return;
    }

    setState(() {
      _video = loaded;
      _videoReady = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous?.dispose();
    });
  }

  Future<VideoPlayerController?> _tryLoadAsset(String asset) async {
    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return null;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return null;
      }
      return controller;
    } catch (_) {
      await controller.dispose();
      return null;
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

    if (PremiumStore.isGatedRoute(item.route)) {
      final section = ActivitySection.fromRoute(item.route)!;
      final allowed = await PremiumStore.tryConsumeActivityTap(section);
      if (!mounted) return;
      if (!allowed) {
        await showOutOfTapsDialog(context, section: section);
        if (!mounted) return;
        setState(() {
          _selectedRoute = _isSleeping ? '/wake-up' : null;
        });
        return;
      }
    }

    await context.push('${item.route}?character=${character.id.name}');
    if (!mounted) return;
    await _refreshTimers();
    await StarsStore.total();
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
                onSettings: () => context.push('/parent-gate'),
                onProfile: () => context.push('/profile'),
                leading: TtBackButton(
                  onPressed: () => context.go('/select'),
                  semanticLabel: 'Back to family',
                ),
              ),
              if (comingSoon)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    '${character.name} Coming Soon',
                    textAlign: TextAlign.center,
                    style: TTTypography.headline(color: TTColors.darkBrown)
                        .copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                )
              else if (_isBao && _sleepLoaded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    _isSleeping ? 'Bao is sleeping' : 'Hello Bao!',
                    textAlign: TextAlign.center,
                    style: TTTypography.headline(color: TTColors.darkBrown)
                        .copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
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
                            Text(
                              character.name,
                              style: TTTypography.headline(
                                color: TTColors.darkBrown,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 30,
                              ),
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
    final emphasize = selected || due;
    final labelColor = emphasize ? _selectedLabel : _inactive;

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
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
                // Always a light disc so icons stay readable on the frosted bar.
                color: emphasize
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.88),
                border: Border.all(
                  color: due ? accent : Colors.white.withValues(alpha: 0.95),
                  width: due ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (due ? accent : TTColors.darkBrown)
                        .withValues(alpha: due ? 0.35 : 0.12),
                    blurRadius: due ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(item.icon, color: _inactive, size: 22),
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
