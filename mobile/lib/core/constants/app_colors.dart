import 'package:flutter/material.dart';

class AppColors {
  // Soft Pastel Minimalist — Light Mode
  static const Color lightBg = Color(0xFFF8F7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF242A30);
  static const Color lightMuted = Color(0xFF6C757D);
  static const Color lightLine = Color(0xFFE8E4DC);
  static const Color lightBoxLine = Color(0xFF8FA1AC);
  static const Color lightTabBg = Color(0xFFEBE7DF);
  static const Color lightAccent = Color(0xFF3F7E68);
  static const Color lightAccentInk = Color(0xFFFFFFFF);
  static const Color lightAccentSoft = Color(0xFFDCECE4);
  static const Color lightGold = Color(0xFFD9A12F);
  static const Color lightGoldInk = Color(0xFF6D5214);
  static const Color lightGoldSoft = Color(0xFFF6ECD2);
  static const Color lightMiss = Color(0xFFB4533F);
  static const Color lightMissSoft = Color(0xFFF6E1DB);

  // Module Soft Pastels — Light
  static const Color lightPastelSky = Color(0xFFDCEBF5);
  static const Color lightPastelSkyInk = Color(0xFF22536F);
  static const Color lightPastelLavender = Color(0xFFEAE3F6);
  static const Color lightPastelLavenderInk = Color(0xFF4A396B);
  static const Color lightPastelBlush = Color(0xFFF6DFE4);
  static const Color lightPastelBlushInk = Color(0xFF723140);
  static const Color lightPastelPeach = Color(0xFFF7E5DA);
  static const Color lightPastelPeachInk = Color(0xFF713F26);

  // Soft Pastel Minimalist — Dark Mode
  static const Color darkBg = Color(0xFF15171A);
  static const Color darkSurface = Color(0xFF1D2024);
  static const Color darkInk = Color(0xFFECEAE6);
  static const Color darkMuted = Color(0xFF98A0A8);
  static const Color darkLine = Color(0xFF2B2F36);
  static const Color darkBoxLine = Color(0xFF6B7D89);
  static const Color darkTabBg = Color(0xFF24282E);
  static const Color darkAccent = Color(0xFF7CC2A8);
  static const Color darkAccentInk = Color(0xFF11221B);
  static const Color darkAccentSoft = Color(0xFF21382F);
  static const Color darkGold = Color(0xFFE3B04B);
  static const Color darkGoldInk = Color(0xFFEBD293);
  static const Color darkGoldSoft = Color(0xFF352E1B);
  static const Color darkMiss = Color(0xFFE39A88);
  static const Color darkMissSoft = Color(0xFF3A2420);

  // Module Soft Pastels — Dark
  static const Color darkPastelSky = Color(0xFF1E3240);
  static const Color darkPastelSkyInk = Color(0xFF9BCEEB);
  static const Color darkPastelLavender = Color(0xFF2C253A);
  static const Color darkPastelLavenderInk = Color(0xFFC9B9EA);
  static const Color darkPastelBlush = Color(0xFF3A2228);
  static const Color darkPastelBlushInk = Color(0xFFEBADB9);
  static const Color darkPastelPeach = Color(0xFF3A281E);
  static const Color darkPastelPeachInk = Color(0xFFEBBFA5);

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

  static Color pastelSky(BuildContext context) => isDark(context) ? darkPastelSky : lightPastelSky;
  static Color pastelSkyInk(BuildContext context) => isDark(context) ? darkPastelSkyInk : lightPastelSkyInk;
  static Color pastelLavender(BuildContext context) => isDark(context) ? darkPastelLavender : lightPastelLavender;
  static Color pastelLavenderInk(BuildContext context) => isDark(context) ? darkPastelLavenderInk : lightPastelLavenderInk;
  static Color pastelBlush(BuildContext context) => isDark(context) ? darkPastelBlush : lightPastelBlush;
  static Color pastelBlushInk(BuildContext context) => isDark(context) ? darkPastelBlushInk : lightPastelBlushInk;
  static Color pastelPeach(BuildContext context) => isDark(context) ? darkPastelPeach : lightPastelPeach;
  static Color pastelPeachInk(BuildContext context) => isDark(context) ? darkPastelPeachInk : lightPastelPeachInk;
}
