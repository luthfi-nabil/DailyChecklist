import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static bool useFonts = true;

  static ThemeData light({bool useGoogleFonts = true, String palette = 'pink'}) {
    useFonts = useGoogleFonts;
    final spec = AppColors.specFor(palette);
    final baseText = ThemeData.light().textTheme;
    final textTheme = useGoogleFonts ? GoogleFonts.dmSansTextTheme(baseText) : baseText;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: spec.lightBg,
      colorScheme: ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: spec.lightAccent,
        onPrimary: spec.lightAccentInk,
        onSurface: spec.lightInk,
      ),
      textTheme: textTheme.apply(
        bodyColor: spec.lightInk,
        displayColor: spec.lightInk,
      ),
      dividerColor: spec.lightLine,
      extensions: [
        AppPaletteColors(
          bg: spec.lightBg,
          surface: AppColors.lightSurface,
          soft: spec.lightSoft,
          ink: spec.lightInk,
          muted: spec.lightMuted,
          line: spec.lightLine,
          tabBg: spec.lightTabBg,
          accent: spec.lightAccent,
          accentDeep: spec.lightAccentDeep,
          accentInk: spec.lightAccentInk,
          accentSoft: spec.lightAccentSoft,
        ),
      ],
      useMaterial3: true,
    );
  }

  static ThemeData dark({bool useGoogleFonts = true, String palette = 'pink'}) {
    useFonts = useGoogleFonts;
    final spec = AppColors.specFor(palette);
    final baseText = ThemeData.dark().textTheme;
    final textTheme = useGoogleFonts ? GoogleFonts.dmSansTextTheme(baseText) : baseText;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spec.darkBg,
      colorScheme: ColorScheme.dark(
        surface: spec.darkSurface,
        primary: spec.darkAccent,
        onPrimary: spec.darkAccentInk,
        onSurface: AppColors.darkInk,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.darkInk,
        displayColor: AppColors.darkInk,
      ),
      dividerColor: spec.darkLine,
      extensions: [
        AppPaletteColors(
          bg: spec.darkBg,
          surface: spec.darkSurface,
          soft: spec.darkBg,
          ink: AppColors.darkInk,
          muted: AppColors.darkMuted,
          line: spec.darkLine,
          tabBg: AppColors.darkTabBg,
          accent: spec.darkAccent,
          accentDeep: spec.darkAccentDeep,
          accentInk: spec.darkAccentInk,
          accentSoft: spec.darkAccentSoft,
        ),
      ],
      useMaterial3: true,
    );
  }

  static TextStyle displayStyle(
    BuildContext context, {
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.ink(context),
      height: 1.15,
    );
    if (!useFonts) return base;
    try {
      return GoogleFonts.bricolageGrotesque(textStyle: base);
    } catch (_) {
      return base;
    }
  }
}
