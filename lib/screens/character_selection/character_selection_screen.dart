import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/character.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bounce_button.dart';

/// Screen 2 — Character Selection (Family Carousel).
/// Static background image (provided by you) + card carousel that
/// visually matches the approved reference design exactly.
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  late final PageController _pageController;
  double _page = 0;

  // Demo values — wire these to your real player-progress provider.
  final int stars = 125;
  final int beans = 35;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.62);
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  FamilyCharacter get _current =>
      familyCharacters[_page.round().clamp(0, familyCharacters.length - 1)];

  void _flip(int delta) {
    final next =
    (_page.round() + delta).clamp(0, familyCharacters.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
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
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!c.isUnlocked) _showComingSoon(c);
  }

  Future<void> _showComingSoon(FamilyCharacter c) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Coming Soon',
      barrierColor: TTColors.darkBrown.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim, __) {
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
      transitionBuilder: (context, anim, __, child) {
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

  void _openParentGateSettings() => context.push('/parent-gate');

  @override
  Widget build(BuildContext context) {
    final locked = !_current.isUnlocked;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ================= BACKGROUND (STATIC IMAGE) =================
          // TODO: replace with your final artwork. This path is a
          // placeholder; add your file at this location or change the path.
          Image.asset(
            'assets/images/character_select_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: Color(0xFF8FD3F4), // fallback sky-blue if image missing
            ),
          ),

          // ================= FOREGROUND CONTENT =================
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _TopBar(
                  stars: stars,
                  beans: beans,
                  onBack: () => context.pop(),
                  onSettings: _openParentGateSettings,
                ),
                const SizedBox(height: 18),
                // const _TitleLockup(),
                const SizedBox(height: 18),
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
                          final scale = (1 - (dist * 0.12)).clamp(0.88, 1.0);
                          final selected = dist < 0.5;
                          return Align(
                            alignment: Alignment.center,
                            child: Transform.scale(
                              scale: scale,
                              child: GestureDetector(
                                onTap: () => _onCardTap(character, index),
                                child: CharacterCard(
                                  character: character,
                                  selected: selected,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: const Alignment(-1.02, 0),
                        child: _CarouselArrow(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => _flip(-1),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(1.02, 0),
                        child: _CarouselArrow(
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => _flip(1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DotsIndicator(
                  count: familyCharacters.length,
                  activeIndex: _page.round(),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: PlayCtaButton(
                    onPressed: locked ? null : _onPlay,
                    comingSoon: locked,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// TOP BAR — gold back button (left) + star & bean pills (right)
// =====================================================================
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.stars,
    required this.beans,
    required this.onBack,
    required this.onSettings,
  });

  final int stars;
  final int beans;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BounceButton(
            onPressed: onBack,
            semanticLabel: 'Back',
            child: const _BackButtonCircle(),
          ),
          Row(
            children: [
              _CounterPill(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFC93C),
                value: stars,
              ),
              const SizedBox(width: 10),
              _CounterPill(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF4CAF50),
                value: beans,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Back button — chunky 3D gold circle with a white chevron,
/// matching the reference design exactly.
class _BackButtonCircle extends StatelessWidget {
  const _BackButtonCircle();

  static const double _size = 52;
  static const double _baseOffset = 4; // how much the dark base peeks out

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size + _baseOffset,
      child: Stack(
        children: [
          // ---- BASE LAYER: gives the button "thickness" (3D elevation) ----
          Positioned(
            top: _baseOffset,
            left: 0,
            child: Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC77C0E), // deep amber, sits below the face
              ),
            ),
          ),
          // ---- SOFT AMBIENT SHADOW (separate from the base layer) ----
          Positioned(
            top: _baseOffset,
            left: 0,
            child: Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // ---- FACE LAYER: glossy gold gradient + border + icon ----
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD966), Color(0xFFFFB627)],
                  stops: [0.0, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFE8961A),
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF3A2E1F),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// TITLE LOCKUP — layered purple pill + tan pill, exactly like reference
// =====================================================================
// class _TitleLockup extends StatelessWidget {
//   const _TitleLockup();
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.topCenter,
//       clipBehavior: Clip.none,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(top: 34),
//           child: _TanPill(),
//         ),
//         // _PurplePill(),
//       ],
//     );
//   }
// }

// class _PurplePill extends StatelessWidget {
//   const _PurplePill();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 28),
//       padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Color(0xFF7B5FC7), Color(0xFF5B3FA0)],
//         ),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: Colors.white, width: 3),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x33000000),
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 22),
//           const SizedBox(width: 10),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Choose Your',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//               const Text(
//                 'Family Member',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w900,
//                   fontSize: 22,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 10),
//           const Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 22),
//         ],
//       ),
//     );
//   }
// }

// class _TanPill extends StatelessWidget {
//   const _TanPill();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE0B15C),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white, width: 2),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x22000000),
//             blurRadius: 4,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: const [
//           Icon(Icons.favorite_rounded, color: Color(0xFFE0668C), size: 14),
//           SizedBox(width: 8),
//           Text(
//             'Meet Bao & Family',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w700,
//               fontSize: 13,
//             ),
//           ),
//           SizedBox(width: 8),
//           Icon(Icons.favorite_rounded, color: Color(0xFFE0668C), size: 14),
//         ],
//       ),
//     );
//   }
// }

// =====================================================================
// CAROUSEL ARROW — gold circle button
// =====================================================================
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC93C),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8A317), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 30, color: const Color(0xFF7A4E12)),
      ),
    );
  }
}

// =====================================================================
// CHARACTER CARD — image slot + ribbon name + age + unlock pill
// =====================================================================
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
    required this.selected,
  });

  final FamilyCharacter character;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(character.cardColorValue);
    final locked = !character.isUnlocked;

    return Center(
      child: SizedBox(
        width: 230,
        height: 420, // taller so nothing gets cropped/squeezed
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white, // white card body, like the reference
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white,
              width: selected && !locked ? 6 : 5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- IMAGE SLOT ----
                    SizedBox(
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _CharacterImageSlot(
                          character: character,
                          locked: locked,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26), // room for ribbon overlap
                    Text(
                      'Age ${character.subtitle}',
                      textAlign: TextAlign.center,
                      style: TTTypography.body(color: TTColors.darkBrown)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    _UnlockPill(unlocked: !locked),
                  ],
                ),
              ),

              // ---- RIBBON: overlaps the bottom edge of the image ----
              Positioned(
                top: 220 + 10 - 18, // imageHeight + topPadding - half ribbon height
                left: 0,
                right: 0,
                child: Center(
                  child: _RibbonBanner(
                    text: character.name,
                    color: _ribbonColorFor(cardColor),
                  ),
                ),
              ),

              if (locked)
                Positioned(
                  top: -8,
                  right: -6,
                  child: Transform.rotate(
                    angle: 0.18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF6C4D),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Coming Soon!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _ribbonColorFor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Image slot for each character card.
class _CharacterImageSlot extends StatelessWidget {
  const _CharacterImageSlot({required this.character, required this.locked});

  final FamilyCharacter character;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final path = 'assets/images/characters/${character.id.name}.png';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Color(character.cardColorValue).withValues(alpha: 0.25),
        ),
        Image.asset(
          path,
          fit: BoxFit.cover, // fills the slot, no cropping since slot is
                              // now correctly sized for the card height
          errorBuilder: (context, error, stack) => Container(
            color: Color(character.cardColorValue).withValues(alpha: 0.35),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add ${character.name}\nimage here',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (locked)
          Container(
            color: Colors.white.withValues(alpha: 0.45),
            child: const Center(
              child: Icon(
                Icons.lock_rounded,
                size: 44,
                color: Color(0xFFB08900),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ribbon-style nameplate with pointed folded ends, matching reference.
class _RibbonBanner extends StatelessWidget {
  const _RibbonBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        color: color,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 8.0;
    final path = Path()
      ..moveTo(notch, 0)
      ..lineTo(size.width - notch, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - notch, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _UnlockPill extends StatelessWidget {
  const _UnlockPill({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? const Color(0xFF4CAF50) : const Color(0xFF9AA0A6);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFDFF4E2) : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              unlocked ? 'Unlocked' : 'Coming Soon',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// DOTS INDICATOR — worm-style pagination
// =====================================================================
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFC93C) : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

// =====================================================================
// PLAY CTA BUTTON — 3D green pill button
// =====================================================================
class PlayCtaButton extends StatelessWidget {
  const PlayCtaButton({
    super.key,
    required this.onPressed,
    required this.comingSoon,
  });

  final VoidCallback? onPressed;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = comingSoon
        ? const [Color(0xFFBDBDBD), Color(0xFF8E8E8E)]
        : const [Color(0xFF7ED957), Color(0xFF3FA34D)];
    final borderColor =
    comingSoon ? const Color(0xFF6E6E6E) : const Color(0xFF2E7D32);

    return BounceButton(
      onPressed: onPressed ?? () {},
      semanticLabel: comingSoon ? 'Coming Soon' : 'Play',
      child: Container(
        width: double.infinity,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                comingSoon ? Icons.lock_rounded : Icons.play_arrow_rounded,
                color: comingSoon
                    ? const Color(0xFF8E8E8E)
                    : const Color(0xFF3FA34D),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              comingSoon ? 'Coming Soon' : 'Play',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// COMING SOON POPUP
// =====================================================================
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
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
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/characters/${character.id.name}.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.waving_hand_rounded,
                  size: 40,
                  color: Color(0xFF7A6A5A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(character.name, style: TTTypography.title()),
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
                color: const Color(0xFFFFC93C),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text('OK', style: TTTypography.button()),
            ),
          ),
        ],
      ),
    );
  }
}
