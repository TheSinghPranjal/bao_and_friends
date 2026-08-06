import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/status_bar.dart';

/// Screen 1 — Splash.
/// Full-screen looping background video (unblurred, unfiltered) +
/// top-pinned brand logo + bottom-pinned "Loading..." progress bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _videoAsset = 'assets/videos/splash_screen_bg_video.mp4';
  static const _logoAsset = 'assets/images/logo_splash_screen.png';
  static const _minDisplay = Duration(milliseconds: 3200);

  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _navigated = false;

  late final AnimationController _intro;
  late final AnimationController _exit;
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _loaderFade;
  late final Animation<double> _exitBloom;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
    _loaderFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _exitBloom = CurvedAnimation(parent: _exit, curve: Curves.easeInOut);

    _intro.forward();
    _initVideo();
    Future<void>.delayed(_minDisplay, _finishSplash);
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() {
        _video = controller;
        _videoReady = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }
  }

  Future<void> _finishSplash() async {
    if (!mounted || _navigated) return;
    await _exit.forward();
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go('/select');
  }

  @override
  void dispose() {
    _navigated = true;
    _intro.dispose();
    _exit.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = screenWidth * 0.7;

    return Scaffold(
      backgroundColor: TTColors.peachSoft,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _exit]),
        builder: (context, _) {
          final bloom = _exitBloom.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background video — no blur, no darkening filter.
              Opacity(
                opacity: _bgFade.value,
                child: _SplashBackground(
                  controller: _video,
                  ready: _videoReady,
                  failed: _videoFailed,
                ),
              ),

              // Logo pinned to TOP + Loading bar pinned to BOTTOM.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TTSpacing.safe,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      // ---- TOP: LOGO ----
                      Transform.scale(
                        scale: _logoScale.value * (1 + bloom * 0.08),
                        child: Opacity(
                          opacity: (1 - bloom).clamp(0.0, 1.0),
                          child: Semantics(
                            label: 'Tiny Think – Learning Together',
                            image: true,
                            child: Image.asset(
                              _logoAsset,
                              width: logoWidth,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),

                      // ---- MIDDLE: transparent, video shows through ----
                      const Spacer(),

                      // ---- BOTTOM: "Loading..." + progress bar ----
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Opacity(
                          opacity: _loaderFade.value * (1 - bloom),
                          child: const _LoadingIndicator(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exit-only white bloom (transition to next screen), never
              // visible during normal idle/loading state.
              IgnorePointer(
                child: Container(
                  color: TTColors.warmWhite.withValues(alpha: bloom),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-bleed background video renderer — BoxFit.cover, zero blur / zero
/// color filters, so the scene stays bright and crisp exactly like the
/// reference artwork.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground({
    required this.controller,
    required this.ready,
    required this.failed,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;

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
              child: VideoPlayer(controller!),
            ),
          ),
        ),
      );
    }

    return const ColoredBox(color: TTColors.peachSoft);
  }
}

/// "Loading..." label + rounded gradient progress bar, matching the
/// reference screenshot. Uses an indeterminate sliding-gradient animation
/// since actual asset load time is variable.
class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loading...',
          // style: TTTypography.body.copyWith(
          //   fontWeight: FontWeight.w700,
          //   color: TTColors.darkBrown,
          //   fontSize: 18,
          // ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 220,
          height: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Track
                Container(color: const Color(0xFFE3E7EC)),
                // Animated gradient fill sliding left → right, looping.
                AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) {
                    final t = _loop.value; // 0..1
                    return Align(
                      alignment: Alignment(-1 + 2 * t, 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF7FD8F5),
                                Color(0xFF2E9BF0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
