import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/character.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Screen 2 — Character Selection (Family Carousel).
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _ringSpin;
  late final AnimationController _butterfly;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.72);
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
    _ringSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _butterfly = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ringSpin.dispose();
    _butterfly.dispose();
    super.dispose();
  }

  FamilyCharacter get _current =>
      familyCharacters[_page.round().clamp(0, familyCharacters.length - 1)];

  void _flip(int delta) {
    final next = (_page.round() + delta).clamp(0, familyCharacters.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPlay() {
    final c = _current;
    if (!c.isUnlocked) {
      _showComingSoon(c);
      return;
    }
    context.go('/home/${c.id.name}');
  }

  void _onCardTap(FamilyCharacter c, int index) {
    if ((_page.round() - index).abs() > 0) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!c.isUnlocked) {
      _showComingSoon(c);
    }
  }

  Future<void> _showComingSoon(FamilyCharacter c) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Coming Soon',
      barrierColor: TTColors.darkBrown.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ComingSoonPopup(
              character: c,
              onOk: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _openParentGateSettings() {
    context.push('/parent-gate');
  }

  @override
  Widget build(BuildContext context) {
    final locked = !_current.isUnlocked;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _butterfly,
            builder: (context, _) =>
                _ParkBackground(t: _butterfly.value),
          ),
          Column(
            children: [
              TinyStatusBar(
                showCounters: false,
                onSettings: _openParentGateSettings,
                leading: BounceButton(
                  onPressed: _openParentGateSettings,
                  semanticLabel: 'Tiny Think',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TTColors.creamWhite,
                      border: Border.all(color: TTColors.skyBlue, width: 2),
                      boxShadow: TTShadows.soft,
                    ),
                    child: const Center(child: BaoFace(size: 34)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Who do you want to play with today?',
                  textAlign: TextAlign.center,
                  style: TTTypography.headline(color: TTColors.darkBrown),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: familyCharacters.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final character = familyCharacters[index];
                        final dist = (_page - index).abs();
                        final scale = (1 - (dist * 0.18)).clamp(0.78, 1.0);
                        final selected = dist < 0.5;
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: (1 - dist * 0.25).clamp(0.55, 1.0),
                            child: GestureDetector(
                              onTap: () => _onCardTap(character, index),
                              child: CharacterCard(
                                character: character,
                                selected: selected,
                                ringAnimation: _ringSpin,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Arrow buttons
                    Positioned(
                      left: 8,
                      child: _CarouselArrow(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => _flip(-1),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      child: _CarouselArrow(
                        icon: Icons.chevron_right_rounded,
                        onPressed: () => _flip(1),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: PlayCtaButton(
                  onPressed: locked ? null : _onPlay,
                  comingSoon: locked,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: onPressed,
      semanticLabel: 'Flip carousel',
      child: Container(
        width: TTSpacing.touchMin,
        height: TTSpacing.touchMin,
        decoration: BoxDecoration(
          color: TTColors.creamWhite,
          shape: BoxShape.circle,
          boxShadow: TTShadows.soft,
        ),
        child: Icon(icon, size: 36, color: TTColors.darkBrown),
      ),
    );
  }
}

class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
    required this.selected,
    required this.ringAnimation,
  });

  final FamilyCharacter character;
  final bool selected;
  final Animation<double> ringAnimation;

  @override
  Widget build(BuildContext context) {
    final color = Color(character.cardColorValue);
    final locked = !character.isUnlocked;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: TTSpacing.touchCardMinW,
          minHeight: TTSpacing.touchCardMinH,
          maxWidth: 280,
        ),
        child: AnimatedBuilder(
          animation: ringAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: selected && !locked
                  ? _DashedRingPainter(
                      progress: ringAnimation.value,
                      color: TTColors.golden,
                    )
                  : null,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
              border: Border.all(color: TTColors.creamWhite, width: 5),
              boxShadow: TTShadows.lift,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Portrait
                          Opacity(
                            opacity: locked ? 0.6 : 1,
                            child: _CharacterPortrait(character: character),
                          ),
                          if (locked) ...[
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(TTSpacing.radiusLg),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                child: Container(
                                  color: TTColors.frosted.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.lock_rounded,
                              size: 48,
                              color: TTColors.lockGold,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      character.name,
                      style: TTTypography.title(color: TTColors.darkBrown),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TTTypography.caption(color: TTColors.softBrown),
                    ),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: -8,
                    right: -4,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: const _ComingSoonRibbon(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterPortrait extends StatelessWidget {
  const _CharacterPortrait({required this.character});

  final FamilyCharacter character;

  @override
  Widget build(BuildContext context) {
    // Bao uses the locked face painter; others use soft silhouette placeholders
    // matching card color until final 3D busts arrive.
    if (character.id == CharacterId.bao) {
      return const BaoFace(size: 140);
    }
    if (character.id == CharacterId.poko) {
      return Stack(
        alignment: Alignment.center,
        children: [
          const BaoFace(size: 140), // same species; outfit differs in final art
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TTColors.pokoPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Poko',
                style: TTTypography.caption(color: TTColors.darkBrown),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 36,
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: TTColors.golden.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _iconFor(character.id),
          size: 88,
          color: TTColors.darkBrown.withValues(alpha: 0.55),
        ),
        Text(
          '3D portrait placeholder',
          style: TTTypography.caption(
            color: TTColors.darkBrown.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(CharacterId id) {
    switch (id) {
      case CharacterId.po:
        return Icons.sports_soccer_rounded;
      case CharacterId.koko:
        return Icons.palette_rounded;
      case CharacterId.momo:
        return Icons.favorite_rounded;
      case CharacterId.dodo:
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.pets_rounded;
    }
  }
}

class _ComingSoonRibbon extends StatefulWidget {
  const _ComingSoonRibbon();

  @override
  State<_ComingSoonRibbon> createState() => _ComingSoonRibbonState();
}

class _ComingSoonRibbonState extends State<_ComingSoonRibbon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flutter;

  @override
  void initState() {
    super.initState();
    _flutter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flutter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flutter,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_flutter.value - 0.5) * 0.08,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TTColors.ribbonOrange,
          borderRadius: BorderRadius.circular(8),
          boxShadow: TTShadows.soft,
        ),
        child: Text('Coming Soon!', style: TTTypography.ribbon()),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    const dash = 10.0;
    const gap = 8.0;
    var distance = progress * (dash + gap);
    while (distance < metrics.length) {
      final next = math.min(distance + dash, metrics.length);
      canvas.drawPath(metrics.extractPath(distance, next), paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ComingSoonPopup extends StatelessWidget {
  const ComingSoonPopup({
    super.key,
    required this.character,
    required this.onOk,
  });

  final FamilyCharacter character;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusXl),
        boxShadow: TTShadows.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(character.cardColorValue),
              border: Border.all(color: TTColors.creamWhite, width: 4),
            ),
            child: character.id == CharacterId.bao ||
                    character.id == CharacterId.poko
                ? const Center(child: BaoFace(size: 72))
                : Icon(
                    Icons.waving_hand_rounded,
                    size: 48,
                    color: TTColors.darkBrown.withValues(alpha: 0.6),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            character.name,
            style: TTTypography.title(),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm getting ready to play with you soon!",
            textAlign: TextAlign.center,
            style: TTTypography.body(),
          ),
          const SizedBox(height: 20),
          BounceButton(
            onPressed: onOk,
            semanticLabel: 'OK',
            child: Container(
              constraints: const BoxConstraints(minWidth: 140, minHeight: 56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TTColors.golden,
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
                boxShadow: TTShadows.soft,
              ),
              child: Text('OK', style: TTTypography.button()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkBackground extends StatelessWidget {
  const _ParkBackground({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParkPainter(t: t),
      child: const SizedBox.expand(),
    );
  }
}

class _ParkPainter extends CustomPainter {
  _ParkPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient — late afternoon golden hour
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [TTColors.parkSkyTop, TTColors.parkSkyBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Soft clouds
    final cloudPaint = Paint()
      ..color = TTColors.creamWhite.withValues(alpha: 0.55);
    final cloudShift = t * size.width * 0.08;
    _cloud(canvas, Offset(size.width * 0.15 + cloudShift, size.height * 0.12),
        40, cloudPaint);
    _cloud(canvas, Offset(size.width * 0.7 - cloudShift * 0.5, size.height * 0.18),
        32, cloudPaint);

    // Hills (depth of field — softer back hill)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.72),
        width: size.width * 1.2,
        height: size.height * 0.45,
      ),
      Paint()..color = TTColors.parkGreen.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.82),
        width: size.width * 1.3,
        height: size.height * 0.4,
      ),
      Paint()..color = TTColors.parkGreenDeep.withValues(alpha: 0.75),
    );

    // Shade tree
    final treeX = size.width * 0.18;
    final sway = math.sin(t * math.pi * 2) * 4;
    canvas.drawRect(
      Rect.fromLTWH(treeX - 8, size.height * 0.42, 16, size.height * 0.28),
      Paint()..color = const Color(0xFF8B6914),
    );
    canvas.drawCircle(
      Offset(treeX + sway, size.height * 0.38),
      58,
      Paint()..color = TTColors.parkGreenDeep,
    );
    canvas.drawCircle(
      Offset(treeX - 30 + sway * 0.5, size.height * 0.42),
      36,
      Paint()..color = TTColors.parkGreen,
    );

    // Butterflies
    final bf = Paint()..color = TTColors.pokoPink;
    final bf2 = Paint()..color = TTColors.golden;
    final bx = size.width * (0.4 + 0.35 * math.sin(t * math.pi * 2));
    final by = size.height * (0.35 + 0.08 * math.cos(t * math.pi * 4));
    canvas.drawCircle(Offset(bx, by), 4, bf);
    canvas.drawCircle(Offset(bx + 8, by - 2), 3.5, bf);
    final bx2 = size.width * (0.55 + 0.25 * math.cos(t * math.pi * 2));
    final by2 = size.height * (0.28 + 0.1 * math.sin(t * math.pi * 3));
    canvas.drawCircle(Offset(bx2, by2), 3.5, bf2);
    canvas.drawCircle(Offset(bx2 + 7, by2 + 1), 3, bf2);

    // Foreground grass
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      Paint()..color = TTColors.parkGreenDeep,
    );
  }

  void _cloud(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c.translate(-r * 0.7, 8), r * 0.7, paint);
    canvas.drawCircle(c.translate(r * 0.65, 10), r * 0.65, paint);
  }

  @override
  bool shouldRepaint(covariant _ParkPainter oldDelegate) => oldDelegate.t != t;
}
