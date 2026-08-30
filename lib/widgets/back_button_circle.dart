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
      child: const GoldCircleIcon(icon: Icons.chevron_left_rounded),
    );
  }
}

/// Settings control — same gold circle UI as the back button.
class TtSettingsButton extends StatelessWidget {
  const TtSettingsButton({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Settings',
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: const GoldCircleIcon(icon: Icons.settings_rounded, iconSize: 26),
    );
  }
}

/// Chunky 3D gold circle with a white icon — shared by back + settings.
class GoldCircleIcon extends StatelessWidget {
  const GoldCircleIcon({
    super.key,
    required this.icon,
    this.iconSize = 30,
  });

  final IconData icon;
  final double iconSize;

  static const double _size = 52;
  static const double _baseOffset = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size + _baseOffset,
      child: Stack(
        children: [
          Positioned(
            top: _baseOffset,
            left: 0,
            child: Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC77C0E),
              ),
            ),
          ),
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
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back-compat — same face as [GoldCircleIcon] with the back chevron.
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoldCircleIcon(icon: Icons.chevron_left_rounded);
  }
}
