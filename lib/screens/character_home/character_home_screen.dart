import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/character.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Character Home — bedroom with floating activity bubbles.
class CharacterHomeScreen extends StatefulWidget {
  const CharacterHomeScreen({super.key, required this.characterId});

  final String characterId;

  @override
  State<CharacterHomeScreen> createState() => _CharacterHomeScreenState();
}

class _CharacterHomeScreenState extends State<CharacterHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _idle;
  late FamilyCharacter character;
  int stars = 12;
  int beans = 3;
  int level = 2;


  static const _bubbles = <_BubbleSpec>[
    _BubbleSpec('Learn', Icons.menu_book_rounded, TTColors.skyBlue, '/learn'),
    _BubbleSpec('Feed', Icons.restaurant_rounded, TTColors.momoCoral, '/feed'),
    _BubbleSpec(
      'Drink',
      Icons.water_drop_rounded,
      TTColors.waterBlue,
      '/drink',
    ),
    _BubbleSpec('Play', Icons.sports_esports_rounded, TTColors.golden, '/play'),
    _BubbleSpec(
      'Chores',
      Icons.wb_sunny_rounded,
      TTColors.bambooLight,
      '/chores',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final id = CharacterId.values.firstWhere(
      (e) => e.name == widget.characterId,
      orElse: () => CharacterId.bao,
    );
    character = characterById(id);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _openBubble(_BubbleSpec b) {
    context.push('${b.route}?character=${character.id.name}');
  }

  @override
  Widget build(BuildContext context) {
    final comingSoon = !character.isUnlocked;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeBedroomBg(),
          Column(
            children: [
              TinyStatusBar(
                stars: stars,
                beans: beans,
                level: level,
                onSettings: () => context.push('/parent-gate'),
                onProfile: () => context.push('/profile'),
                leading: BounceButton(
                  onPressed: () => context.go('/select'),
                  semanticLabel: 'Back to family',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TTColors.creamWhite,
                      boxShadow: TTShadows.soft,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: TTColors.darkBrown,
                    ),
                  ),
                ),
              ),
              if (comingSoon)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${character.name} is Coming Soon!',
                    style: TTTypography.headline(),
                  ),
                ),
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_float, _idle]),
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final center = Offset(w / 2, h * 0.55);

                        return Stack(
                          children: [
                            // Floating bubbles around Bao
                            for (var i = 0; i < _bubbles.length; i++)
                              _FloatingBubble(
                                spec: _bubbles[i],
                                center: center,
                                index: i,
                                total: _bubbles.length,
                                radius: math.min(w, h) * 0.32,
                                t: _float.value,
                                onTap: () => _openBubble(_bubbles[i]),
                              ),
                            // Character center-stage
                            Positioned(
                              left: center.dx - 70,
                              top: center.dy -
                                  70 +
                                  math.sin(_idle.value * math.pi) * -8,
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
                                    child: character.id == CharacterId.bao ||
                                            character.id == CharacterId.poko
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

class _BubbleSpec {
  const _BubbleSpec(this.label, this.icon, this.color, this.route);
  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.spec,
    required this.center,
    required this.index,
    required this.total,
    required this.radius,
    required this.t,
    required this.onTap,
  });

  final _BubbleSpec spec;
  final Offset center;
  final int index;
  final int total;
  final double radius;
  final double t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + (index / total) * math.pi * 2 + t * 0.15;
    final bob = math.sin((t + index * 0.2) * math.pi * 2) * 6;
    final x = center.dx + math.cos(angle) * radius - 44;
    final y = center.dy + math.sin(angle) * radius - 44 + bob;

    return Positioned(
      left: x,
      top: y,
      child: BounceButton(
        onPressed: onTap,
        semanticLabel: spec.label,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: spec.color,
            border: Border.all(color: TTColors.creamWhite, width: 4),
            boxShadow: TTShadows.soft,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, color: TTColors.darkBrown, size: 28),
              Text(
                spec.label,
                style: TTTypography.caption(color: TTColors.darkBrown),
              ),
            ],
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
    // Window
    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.12, size.width * 0.32,
          size.height * 0.22),
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

    // Floor
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFFD4A574).withValues(alpha: 0.55),
    );

    // Soft rug
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
