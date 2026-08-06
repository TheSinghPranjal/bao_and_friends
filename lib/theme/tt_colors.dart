import 'package:flutter/material.dart';

/// Tiny Think – Bao & Friends design tokens.
/// Warm, soft, Pixar-inspired pastels. No harsh reds for errors.
abstract final class TTColors {
  // Brand
  static const cream = Color(0xFFFFF8F0);
  static const creamWhite = Color(0xFFFFFBF5);
  static const warmWhite = Color(0xFFFFF5EB);
  static const peachWall = Color(0xFFF5D5C0);
  static const peachSoft = Color(0xFFF8E4D4);
  static const peachDeep = Color(0xFFE8B89A);

  static const skyBlue = Color(0xFF7EC8E8);
  static const skySoft = Color(0xFFB8E0F0);
  static const skyDeep = Color(0xFF5AADD4);

  static const golden = Color(0xFFF5C542);
  static const goldenBright = Color(0xFFFFD56A);
  static const goldenGlow = Color(0xFFFFE8A0);
  static const goldenOutline = Color(0xFFE8B820);

  static const bamboo = Color(0xFF7CB342);
  static const bambooLight = Color(0xFFAED581);
  static const bambooDeep = Color(0xFF558B2F);

  static const darkBrown = Color(0xFF5C3D2E);
  static const warmBrown = Color(0xFF8B6914);
  static const softBrown = Color(0xFFA67C52);

  // Character card backings
  static const baoBlue = Color(0xFF8ECBE8);
  static const pokoPink = Color(0xFFF5B8C8);
  static const poYellow = Color(0xFFF5D76E);
  static const kokoLavender = Color(0xFFC8B8E8);
  static const momoCoral = Color(0xFFF5A88A);
  static const dodoMint = Color(0xFFA8E0C8);

  // UI
  static const ribbonOrange = Color(0xFFE87850);
  static const lockGold = Color(0xFFD4A017);
  static const softShadow = Color(0x33000000);
  static const frosted = Color(0x99FFFFFF);
  static const parkGreen = Color(0xFF8FBF6A);
  static const parkGreenDeep = Color(0xFF6A9A4A);
  static const parkSkyTop = Color(0xFF7EC8E8);
  static const parkSkyBottom = Color(0xFFF5D0B0);
  static const waterBlue = Color(0xFF6EC6E8);
  static const waterDrop = Color(0xFF4DB8E8);

  // Status / needs (always positive)
  static const ready = Color(0xFF7CB342);
  static const interested = Color(0xFFF5C542);
  static const waiting = Color(0xFF7EC8E8);
  static const letsPlay = Color(0xFFE87850);

  // Bao character (locked proportions)
  static const baoFurWhite = Color(0xFFF5F5F5);
  static const baoFurBlack = Color(0xFF2A2A2A);
  static const baoCollar = Color(0xFF4A90D9);
  static const baoEyeWhite = Color(0xFFFFFFFF);
  static const baoIris = Color(0xFF1A1A1A);
}

abstract final class TTShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: TTColors.softShadow,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> lift = [
    BoxShadow(
      color: TTColors.softShadow,
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}
