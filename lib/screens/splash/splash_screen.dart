import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/status_bar.dart';

/// Screen 1 — Splash.
/// Full-screen looping background video + brand logo + bottom loader.
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
    final logoWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Scaffold(
      backgroundColor: TTColors.peachSoft,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _exit]),
        builder: (context, _) {
          final bloom = _exitBloom.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _bgFade.value,
                child: _SplashBackground(
                  controller: _video,
                  ready: _videoReady,
                  failed: _videoFailed,
                ),
              ),
              // Light vignette so logo stays readable on bright frames
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        TTColors.darkBrown.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.transparent,
                        TTColors.darkBrown.withValues(alpha: 0.22),
                      ],
                      stops: const [0.0, 0.25, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(TTSpacing.safe),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
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
                      const Spacer(flex: 3),
                      Opacity(
                        opacity: _loaderFade.value * (1 - bloom),
                        child: const BambooLeafLoader(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
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
