import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color lightBg = Color(0xFFF2F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF1B2730);
  static const Color lightMuted = Color(0xFF566772);
  static const Color lightLine = Color(0xFFD9E1E6);
  static const Color lightBoxLine = Color(0xFF8FA1AC);
  static const Color lightTabBg = Color(0xFFE4EAEE);
  static const Color lightAccent = Color(0xFF1D7487);
  static const Color lightAccentInk = Color(0xFFFFFFFF);
  static const Color lightAccentSoft = Color(0xFFDDEEF2);
  static const Color lightGold = Color(0xFFD9A12F);
  static const Color lightGoldInk = Color(0xFF7A4E0A);
  static const Color lightGoldSoft = Color(0xFFF7E9C8);
  static const Color lightMiss = Color(0xFFB4533F);
  static const Color lightMissSoft = Color(0xFFF6E1DB);

  // Dark Mode
  static const Color darkBg = Color(0xFF12181D);
  static const Color darkSurface = Color(0xFF1A2229);
  static const Color darkInk = Color(0xFFE6EDF2);
  static const Color darkMuted = Color(0xFF93A4B0);
  static const Color darkLine = Color(0xFF2A353E);
  static const Color darkBoxLine = Color(0xFF6B7D89);
  static const Color darkTabBg = Color(0xFF1F2A32);
  static const Color darkAccent = Color(0xFF6CC6D8);
  static const Color darkAccentInk = Color(0xFF0C1A1F);
  static const Color darkAccentSoft = Color(0xFF1C3A42);
  static const Color darkGold = Color(0xFFE3B04B);
  static const Color darkGoldInk = Color(0xFFF0C877);
  static const Color darkGoldSoft = Color(0xFF3A2F16);
  static const Color darkMiss = Color(0xFFE39A88);
  static const Color darkMissSoft = Color(0xFF3A2420);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => isDark(context) ? darkBg : lightBg;
  static Color surface(BuildContext context) => isDark(context) ? darkSurface : lightSurface;
  static Color ink(BuildContext context) => isDark(context) ? darkInk : lightInk;
  static Color muted(BuildContext context) => isDark(context) ? darkMuted : lightMuted;
  static Color line(BuildContext context) => isDark(context) ? darkLine : lightLine;
  static Color boxLine(BuildContext context) => isDark(context) ? darkBoxLine : lightBoxLine;
  static Color tabBg(BuildContext context) => isDark(context) ? darkTabBg : lightTabBg;
  static Color accent(BuildContext context) => isDark(context) ? darkAccent : lightAccent;
  static Color accentInk(BuildContext context) => isDark(context) ? darkAccentInk : lightAccentInk;
  static Color accentSoft(BuildContext context) => isDark(context) ? darkAccentSoft : lightAccentSoft;
  static Color gold(BuildContext context) => isDark(context) ? darkGold : lightGold;
  static Color goldInk(BuildContext context) => isDark(context) ? darkGoldInk : lightGoldInk;
  static Color goldSoft(BuildContext context) => isDark(context) ? darkGoldSoft : lightGoldSoft;
  static Color miss(BuildContext context) => isDark(context) ? darkMiss : lightMiss;
  static Color missSoft(BuildContext context) => isDark(context) ? darkMissSoft : lightMissSoft;
}
