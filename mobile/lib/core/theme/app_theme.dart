import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static bool useFonts = true;

  static ThemeData light({bool useGoogleFonts = true}) {
    useFonts = useGoogleFonts;
    final baseText = ThemeData.light().textTheme;
    final textTheme = useGoogleFonts
        ? GoogleFonts.dmSansTextTheme(baseText)
        : baseText;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.lightAccent,
        onPrimary: AppColors.lightAccentInk,
        onSurface: AppColors.lightInk,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.lightInk,
        displayColor: AppColors.lightInk,
      ),
      dividerColor: AppColors.lightLine,
      useMaterial3: true,
    );
  }

  static ThemeData dark({bool useGoogleFonts = true}) {
    useFonts = useGoogleFonts;
    final baseText = ThemeData.dark().textTheme;
    final textTheme = useGoogleFonts
        ? GoogleFonts.dmSansTextTheme(baseText)
        : baseText;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        primary: AppColors.darkAccent,
        onPrimary: AppColors.darkAccentInk,
        onSurface: AppColors.darkInk,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.darkInk,
        displayColor: AppColors.darkInk,
      ),
      dividerColor: AppColors.darkLine,
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
