import 'package:flutter/material.dart';

import 'bounce_button.dart';

/// Shared Tiny Think back control — bounce tap + chunky 3D gold circle.
class TtBackButton extends StatelessWidget {
  const TtBackButton({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Back',
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: const BackButtonCircle(),
    );
  }
}

/// Back button face — chunky 3D gold circle with a white chevron.
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({super.key});

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
