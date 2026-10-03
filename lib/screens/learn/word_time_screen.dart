import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/learn_topics.dart';
import '../../models/rewards.dart';
import '../../services/music_store.dart';
import '../../services/stars_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';
import '../drink/drink_water_screen.dart' show RewardPopup;

/// Word Time — one looping portrait lesson per 3-letter word.
///
/// Replay restarts the current clip and stays on that word. Next moves on
/// immediately. After the last word, Next celebrates, awards stars, and offers
/// a restart from the first word or a return to Learn.
///
/// Lesson speech follows Parent Settings → Music (on by default). Other learn
/// clips stay muted; this topic plays Bao's voice when music is enabled.
class WordTimeScreen extends StatefulWidget {
  const WordTimeScreen({super.key});

  static const completionTitle = 'Great Job!';

  @override
  State<WordTimeScreen> createState() => _WordTimeScreenState();
}

class _WordTimeScreenState extends State<WordTimeScreen>
    with SingleTickerProviderStateMixin {
  static const _fallbackColor = Color(0xFFC8E6C9);

  late final AnimationController _float;
  int _index = 0;
  bool _celebrating = false;
  bool _advancing = false;
  bool _disposed = false;
  int _loadGen = 0;

  VideoPlayerController? _video;
  bool _ready = false;
  Future<AssetManifest>? _manifest;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    MusicStore.enabledListenable.addListener(_onMusicChanged);
    unawaited(_loadWord(0));
  }

  WordTimeLesson get _lesson => WordTimeLessons.lessons[_index];

  bool get _isLast => _index >= WordTimeLessons.lessons.length - 1;

  /// On when Parent Settings music is enabled. Default is on.
  double get _speechVolume => MusicStore.enabledListenable.value ? 1 : 0;

  void _onMusicChanged() {
    final video = _video;
    if (_disposed || video == null || !video.value.isInitialized) return;
    unawaited(_applyVolume(video));
  }

  Future<void> _applyVolume(VideoPlayerController controller) async {
    try {
      await controller.setVolume(_speechVolume);
    } catch (_) {}
  }

  Future<bool> _hasLessonAsset(String asset) async {
    try {
      _manifest ??= AssetManifest.loadFromAssetBundle(rootBundle);
      final manifest = await _manifest!;
      return manifest.getAssetVariants(asset) != null;
    } catch (_) {
      _manifest = null;
      return false;
    }
  }

  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    try {
      controller.pause();
    } catch (_) {}
    await controller.dispose();
  }

  Future<void> _loadWord(int index) async {
    final gen = ++_loadGen;
    final prev = _video;
    _video = null;
    _ready = false;

    if (mounted && !_disposed) {
      setState(() {
        _ready = false;
        _video = null;
        _index = index;
        _advancing = true;
      });
    } else {
      _index = index;
      _advancing = true;
    }

    await _disposeController(prev);
    if (_disposed || !mounted || gen != _loadGen) return;

    final lesson = WordTimeLessons.lessons[index];
    final exists = await _hasLessonAsset(lesson.asset);
    if (_disposed || !mounted || gen != _loadGen) return;
    if (!exists) {
      setState(() => _advancing = false);
      return;
    }

    final next = VideoPlayerController.asset(lesson.asset);
    try {
      await next.initialize();
      if (!mounted || _disposed || gen != _loadGen) {
        await _disposeController(next);
        return;
      }
      await next.setLooping(true);
      await _applyVolume(next);
      if (!mounted || _disposed || gen != _loadGen) {
        await _disposeController(next);
        return;
      }
      await next.play();
      if (!mounted || _disposed || gen != _loadGen) {
        await _disposeController(next);
        return;
      }

      setState(() {
        _video = next;
        _ready = true;
        _advancing = false;
      });
    } catch (_) {
      await _disposeController(next);
      if (mounted && !_disposed && gen == _loadGen) {
        setState(() {
          _video = null;
          _ready = false;
          _advancing = false;
        });
      }
    }
  }

  Future<void> _replay() async {
    if (_celebrating || _advancing || _disposed) return;
    final video = _video;
    if (video != null && video.value.isInitialized) {
      try {
        await video.seekTo(Duration.zero);
        if (_disposed || !mounted) return;
        await _applyVolume(video);
        await video.play();
      } catch (_) {
        if (!_disposed && mounted) {
          await _loadWord(_index);
        }
      }
      return;
    }
    await _loadWord(_index);
  }

  Future<void> _advance() async {
    if (_celebrating || _advancing || _disposed) return;
    if (mounted) {
      setState(() => _advancing = true);
    } else {
      _advancing = true;
    }

    if (_isLast) {
      await _finish();
      return;
    }
    await _loadWord(_index + 1);
  }

  Future<void> _finish() async {
    if (_celebrating || _disposed) return;
    final video = _video;
    try {
      await video?.pause();
    } catch (_) {}
    if (!mounted || _disposed) return;
    setState(() {
      _celebrating = true;
      _advancing = false;
    });

    final reward = LearnWordTimeRules.rewardForComplete();
    await StarsStore.add(reward.stars);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _disposed) return;
    await _showReward(reward);
  }

  Future<void> _restart() async {
    if (_disposed || _advancing) return;
    setState(() => _celebrating = false);
    await _loadWord(0);
  }

  void _returnToLearn() {
    context.pop(true);
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
  void dispose() {
    _disposed = true;
    _loadGen++;
    MusicStore.enabledListenable.removeListener(_onMusicChanged);
    final video = _video;
    _video = null;
    _ready = false;
    _float.dispose();
    video?.pause();
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                  Color(0xFFE8F5E9),
                  Color(0xFFC8E6C9),
                  Color(0xFFA5D6A7),
                ],
              ),
            ),
          ),
          if (!_celebrating && _ready)
            _WordTimeVideoLayer(controller: _video, ready: _ready)
          else if (!_celebrating)
            const ColoredBox(color: _fallbackColor),
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
                leading: TtBackButton(
                  onPressed: () => context.pop(_celebrating),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    WordTimeLessons.screenTitle,
                    textAlign: TextAlign.center,
                    style: TTTypography.headline(color: TTColors.darkBrown)
                        .copyWith(fontWeight: FontWeight.w900, fontSize: 28),
                  ),
                ),
              ),
              if (!_celebrating) ...[
                const SizedBox(height: 4),
                Text(
                  '${_index + 1} / ${WordTimeLessons.lessons.length}',
                  style: TTTypography.caption(color: TTColors.darkBrown),
                ),
              ],
              Expanded(
                child: _celebrating
                    ? _WordTimeCompleteBody(
                        message: LearnWordTimeRules.rewardForComplete().message,
                      )
                    : _ready
                    ? const SizedBox.expand()
                    : _WordTimeFallback(word: _lesson.word),
              ),
              AnimatedBuilder(
                animation: _float,
                builder: (context, child) {
                  final bob = math.sin(_float.value * math.pi * 2) * 8;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 28 + bottomInset),
                    child: Transform.translate(
                      offset: Offset(0, -bob),
                      child: child,
                    ),
                  );
                },
                child: _celebrating
                    ? _CompletionActions(
                        onRestart: () => unawaited(_restart()),
                        onLearn: _returnToLearn,
                        enabled: !_advancing,
                      )
                    : _LessonActions(
                        onReplay: _celebrating || _advancing
                            ? null
                            : () => unawaited(_replay()),
                        onNext: _celebrating || _advancing
                            ? null
                            : () => unawaited(_advance()),
                        enabled: !_celebrating && !_advancing,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordTimeFallback extends StatelessWidget {
  const _WordTimeFallback({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
        decoration: BoxDecoration(
          color: TTColors.creamWhite.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
          boxShadow: TTShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BaoFace(size: 140),
            const SizedBox(height: 12),
            Text(
              word,
              key: const Key('word-time-word'),
              textAlign: TextAlign.center,
              style: TTTypography.displayHero(color: TTColors.darkBrown)
                  .copyWith(fontSize: 56, letterSpacing: 6, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordTimeCompleteBody extends StatelessWidget {
  const _WordTimeCompleteBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              WordTimeScreen.completionTitle,
              textAlign: TextAlign.center,
              style: TTTypography.headline(color: TTColors.darkBrown).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 12),
            const BaoFace(size: 120),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TTTypography.body(color: TTColors.darkBrown),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonActions extends StatelessWidget {
  const _LessonActions({
    required this.onReplay,
    required this.onNext,
    required this.enabled,
  });

  final VoidCallback? onReplay;
  final VoidCallback? onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BounceButton(
          onPressed: onReplay,
          enabled: enabled,
          semanticLabel: 'Replay word',
          child: const _WordTimeCircleButton(
            icon: Icons.replay_rounded,
            label: 'Replay',
          ),
        ),
        BounceButton(
          onPressed: onNext,
          enabled: enabled,
          semanticLabel: 'Next word',
          child: const _WordTimeCircleButton(
            icon: Icons.arrow_forward_rounded,
            label: 'Next',
          ),
        ),
      ],
    );
  }
}

class _CompletionActions extends StatelessWidget {
  const _CompletionActions({
    required this.onRestart,
    required this.onLearn,
    required this.enabled,
  });

  final VoidCallback onRestart;
  final VoidCallback onLearn;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BounceButton(
            onPressed: onRestart,
            enabled: enabled,
            semanticLabel: 'Restart from CAT',
            child: const _WordTimePill(
              label: 'Restart from CAT',
              icon: Icons.replay_rounded,
              fill: TTColors.bamboo,
              shadow: TTColors.bambooDeep,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BounceButton(
            onPressed: onLearn,
            enabled: enabled,
            semanticLabel: 'Back to Learn',
            child: const _WordTimePill(
              label: 'Back to Learn',
              icon: Icons.arrow_back_rounded,
              fill: TTColors.golden,
              shadow: TTColors.goldenOutline,
            ),
          ),
        ),
      ],
    );
  }
}

class _WordTimeCircleButton extends StatelessWidget {
  const _WordTimeCircleButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 1.0,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFC8E6C9).withValues(alpha: 0.7),
                  const Color(0xFF81C784).withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.90),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: TTColors.bambooDeep.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: TTColors.bambooDeep),
              Text(
                label,
                style: TTTypography.caption(color: TTColors.darkBrown),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordTimePill extends StatelessWidget {
  const _WordTimePill({
    required this.label,
    required this.icon,
    required this.fill,
    required this.shadow,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: TTSpacing.touchMin),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.45),
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: TTColors.darkBrown),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TTTypography.button(color: TTColors.darkBrown)
                  .copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTimeVideoLayer extends StatelessWidget {
  const _WordTimeVideoLayer({required this.controller, required this.ready});

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final video = controller;
    if (!ready || video == null || !video.value.isInitialized) {
      return const SizedBox.expand();
    }

    final size = video.value.size;
    // Portrait 9:16 lesson, cropped to the screen. UI stays in the overlay.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width > 0 ? size.width : 1080,
          height: size.height > 0 ? size.height : 1920,
          child: VideoPlayer(key: ValueKey(video), video),
        ),
      ),
    );
  }
}
