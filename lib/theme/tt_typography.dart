import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tt_colors.dart';

/// Typography: Baloo 2 for display, Nunito for body (rounded, toddler-friendly).
abstract final class TTTypography {
  static TextStyle displayHero({Color? color}) => GoogleFonts.baloo2(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: 0.5,
        color: color ?? TTColors.creamWhite,
      );

  static TextStyle displayLogo({Color? color}) => GoogleFonts.baloo2(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 1.0,
        color: color ?? TTColors.creamWhite,
        shadows: [
          Shadow(
            color: TTColors.goldenOutline.withValues(alpha: 0.55),
            blurRadius: 12,
          ),
          const Shadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static TextStyle headline({Color? color}) => GoogleFonts.baloo2(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color ?? TTColors.darkBrown,
      );

  static TextStyle title({Color? color}) => GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color ?? TTColors.darkBrown,
      );

  static TextStyle subtitle({Color? color}) => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color ?? TTColors.softBrown,
      );

  static TextStyle body({Color? color}) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color ?? TTColors.darkBrown,
      );

  static TextStyle button({Color? color}) => GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: color ?? TTColors.darkBrown,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color ?? TTColors.softBrown,
      );

  static TextStyle ribbon({Color? color}) => GoogleFonts.baloo2(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 0.4,
        color: color ?? TTColors.creamWhite,
      );
}

abstract final class TTSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double safe = 24;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 999;

  /// Toddler touch targets (well above WCAG 48px).
  static const double touchMin = 64;
  static const double touchCardMinW = 120;
  static const double touchCardMinH = 160;
  static const double playButtonMinW = 200;
  static const double playButtonMinH = 64;

  static const Size designSize = Size(393, 852);
}

ThemeData buildTinyThinkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: TTColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TTColors.skyBlue,
      primary: TTColors.skyDeep,
      secondary: TTColors.golden,
      tertiary: TTColors.bamboo,
      surface: TTColors.creamWhite,
      onPrimary: TTColors.creamWhite,
      onSecondary: TTColors.darkBrown,
      onSurface: TTColors.darkBrown,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: TTColors.darkBrown,
      displayColor: TTColors.darkBrown,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TTTypography.title(),
      iconTheme: const IconThemeData(color: TTColors.darkBrown, size: 28),
    ),
  );
}
