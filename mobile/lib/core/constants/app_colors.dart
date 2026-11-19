import 'package:flutter/material.dart';

class AppPaletteSpec {
  final String id;
  final String label;
  final Color swatchAccent;
  final Color lightBg;
  final Color lightSoft;
  final Color lightInk;
  final Color lightMuted;
  final Color lightLine;
  final Color lightTabBg;
  final Color lightAccent;
  final Color lightAccentDeep;
  final Color lightAccentInk;
  final Color lightAccentSoft;
  final Color darkBg;
  final Color darkSurface;
  final Color darkLine;
  final Color darkAccent;
  final Color darkAccentDeep;
  final Color darkAccentInk;
  final Color darkAccentSoft;

  const AppPaletteSpec({
    required this.id,
    required this.label,
    required this.swatchAccent,
    required this.lightBg,
    required this.lightSoft,
    required this.lightInk,
    required this.lightMuted,
    required this.lightLine,
    required this.lightTabBg,
    required this.lightAccent,
    required this.lightAccentDeep,
    required this.lightAccentInk,
    required this.lightAccentSoft,
    required this.darkBg,
    required this.darkSurface,
    required this.darkLine,
    required this.darkAccent,
    required this.darkAccentDeep,
    required this.darkAccentInk,
    required this.darkAccentSoft,
  });
}

class AppPaletteColors extends ThemeExtension<AppPaletteColors> {
  final Color bg;
  final Color surface;
  final Color soft;
  final Color ink;
  final Color muted;
  final Color line;
  final Color tabBg;
  final Color accent;
  final Color accentDeep;
  final Color accentInk;
  final Color accentSoft;

  const AppPaletteColors({
    required this.bg,
    required this.surface,
    required this.soft,
    required this.ink,
    required this.muted,
    required this.line,
    required this.tabBg,
    required this.accent,
    required this.accentDeep,
    required this.accentInk,
    required this.accentSoft,
  });

  @override
  ThemeExtension<AppPaletteColors> copyWith({
    Color? bg,
    Color? surface,
    Color? soft,
    Color? ink,
    Color? muted,
    Color? line,
    Color? tabBg,
    Color? accent,
    Color? accentDeep,
    Color? accentInk,
    Color? accentSoft,
  }) {
    return AppPaletteColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      soft: soft ?? this.soft,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      tabBg: tabBg ?? this.tabBg,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
    );
  }

  @override
  ThemeExtension<AppPaletteColors> lerp(ThemeExtension<AppPaletteColors>? other, double t) {
    if (other is! AppPaletteColors) return this;
    return AppPaletteColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      tabBg: Color.lerp(tabBg, other.tabBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
    );
  }
}

class AppColors {
  static const List<AppPaletteSpec> palettes = [
    AppPaletteSpec(
      id: 'pink',
      label: 'White & Pink',
      swatchAccent: Color(0xFFED9FBD),
      lightBg: Color(0xFFFFFFFF),
      lightSoft: Color(0xFFFFF7FA),
      lightInk: Color(0xFF493640),
      lightMuted: Color(0xFFA18C96),
      lightLine: Color(0xFFF2E5EB),
      lightTabBg: Color(0xFFFFF0F5),
      lightAccent: Color(0xFFED9FBD),
      lightAccentDeep: Color(0xFFB85F83),
      lightAccentInk: Color(0xFFFFFFFF),
      lightAccentSoft: Color(0xFFFFF0F5),
      darkBg: Color(0xFF181417),
      darkSurface: Color(0xFF221C20),
      darkLine: Color(0xFF382D33),
      darkAccent: Color(0xFFED9FBD),
      darkAccentDeep: Color(0xFFF6C4D7),
      darkAccentInk: Color(0xFF3B1826),
      darkAccentSoft: Color(0xFF33222A),
    ),
    AppPaletteSpec(
      id: 'sage',
      label: 'Soft Pastel Sage',
      swatchAccent: Color(0xFF3F7E68),
      lightBg: Color(0xFFF8F7F4),
      lightSoft: Color(0xFFF2EFE9),
      lightInk: Color(0xFF242A30),
      lightMuted: Color(0xFF6C757D),
      lightLine: Color(0xFFE8E4DC),
      lightTabBg: Color(0xFFEBE7DF),
      lightAccent: Color(0xFF3F7E68),
      lightAccentDeep: Color(0xFF235340),
      lightAccentInk: Color(0xFFFFFFFF),
      lightAccentSoft: Color(0xFFDCECE4),
      darkBg: Color(0xFF15171A),
      darkSurface: Color(0xFF1D2024),
      darkLine: Color(0xFF2B2F36),
      darkAccent: Color(0xFF7CC2A8),
      darkAccentDeep: Color(0xFF9DD6BE),
      darkAccentInk: Color(0xFF11221B),
      darkAccentSoft: Color(0xFF21382F),
    ),
    AppPaletteSpec(
      id: 'teal',
      label: 'Calm Slate Teal',
      swatchAccent: Color(0xFF1D7487),
      lightBg: Color(0xFFF2F5F7),
      lightSoft: Color(0xFFE9EEF1),
      lightInk: Color(0xFF1B2730),
      lightMuted: Color(0xFF566772),
      lightLine: Color(0xFFD9E1E6),
      lightTabBg: Color(0xFFDDEEF2),
      lightAccent: Color(0xFF1D7487),
      lightAccentDeep: Color(0xFF145361),
      lightAccentInk: Color(0xFFFFFFFF),
      lightAccentSoft: Color(0xFFDDEEF2),
      darkBg: Color(0xFF14181B),
      darkSurface: Color(0xFF1C2226),
      darkLine: Color(0xFF2A333A),
      darkAccent: Color(0xFF4CB0C7),
      darkAccentDeep: Color(0xFF9BCEEB),
      darkAccentInk: Color(0xFF0E2329),
      darkAccentSoft: Color(0xFF1B323A),
    ),
    AppPaletteSpec(
      id: 'lavender',
      label: 'Lavender Mist',
      swatchAccent: Color(0xFF8E7AB5),
      lightBg: Color(0xFFFAF8FF),
      lightSoft: Color(0xFFF4F0FC),
      lightInk: Color(0xFF2F283D),
      lightMuted: Color(0xFF7C728D),
      lightLine: Color(0xFFE8E1F5),
      lightTabBg: Color(0xFFEFEAF9),
      lightAccent: Color(0xFF8E7AB5),
      lightAccentDeep: Color(0xFF56437A),
      lightAccentInk: Color(0xFFFFFFFF),
      lightAccentSoft: Color(0xFFEFEAF9),
      darkBg: Color(0xFF17151D),
      darkSurface: Color(0xFF211E29),
      darkLine: Color(0xFF332E40),
      darkAccent: Color(0xFFB19CD9),
      darkAccentDeep: Color(0xFFC9B9EA),
      darkAccentInk: Color(0xFF1D152C),
      darkAccentSoft: Color(0xFF2B223C),
    ),
    AppPaletteSpec(
      id: 'peach',
      label: 'Warm Peach',
      swatchAccent: Color(0xFFE29578),
      lightBg: Color(0xFFFFFDF9),
      lightSoft: Color(0xFFFDF6F2),
      lightInk: Color(0xFF3D2C26),
      lightMuted: Color(0xFF8C756C),
      lightLine: Color(0xFFF2E2DC),
      lightTabBg: Color(0xFFFBECE6),
      lightAccent: Color(0xFFE29578),
      lightAccentDeep: Color(0xFF9C553B),
      lightAccentInk: Color(0xFFFFFFFF),
      lightAccentSoft: Color(0xFFFBECE6),
      darkBg: Color(0xFF1B1614),
      darkSurface: Color(0xFF251E1B),
      darkLine: Color(0xFF3B2E29),
      darkAccent: Color(0xFFEEAE94),
      darkAccentDeep: Color(0xFFEBBFA5),
      darkAccentInk: Color(0xFF2A160F),
      darkAccentSoft: Color(0xFF37241D),
    ),
  ];

  static AppPaletteSpec specFor(String? id) {
    return palettes.firstWhere(
      (p) => p.id == id,
      orElse: () => palettes.first,
    );
  }

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF493640);
  static const Color lightMuted = Color(0xFFA18C96);
  static const Color lightLine = Color(0xFFF2E5EB);
  static const Color lightBoxLine = Color(0xFFB89AA8);
  static const Color lightTabBg = Color(0xFFFFF0F5);
  static const Color lightAccent = Color(0xFFED9FBD);
  static const Color lightAccentDeep = Color(0xFFB85F83);
  static const Color lightAccentInk = Color(0xFFFFFFFF);
  static const Color lightAccentSoft = Color(0xFFFFF0F5);
  static const Color lightGold = Color(0xFFD9A12F);
  static const Color lightGoldInk = Color(0xFF6D5214);
  static const Color lightGoldSoft = Color(0xFFFBF2DF);
  static const Color lightMiss = Color(0xFFB4533F);
  static const Color lightMissSoft = Color(0xFFF6E1DB);

  static const Color lightPastelSky = Color(0xFFE3F0F8);
  static const Color lightPastelSkyInk = Color(0xFF22536F);
  static const Color lightPastelLavender = Color(0xFFEFEAF9);
  static const Color lightPastelLavenderInk = Color(0xFF56437A);
  static const Color lightPastelBlush = Color(0xFFFFF0F5);
  static const Color lightPastelBlushInk = Color(0xFFB85F83);
  static const Color lightPastelPeach = Color(0xFFFBECE6);
  static const Color lightPastelPeachInk = Color(0xFF9C553B);

  static const Color darkBg = Color(0xFF181417);
  static const Color darkSurface = Color(0xFF221C20);
  static const Color darkInk = Color(0xFFF5ECF0);
  static const Color darkMuted = Color(0xFFB09AA4);
  static const Color darkLine = Color(0xFF382D33);
  static const Color darkBoxLine = Color(0xFF6B5B63);
  static const Color darkTabBg = Color(0xFF33222A);
  static const Color darkAccent = Color(0xFFED9FBD);
  static const Color darkAccentDeep = Color(0xFFF6C4D7);
  static const Color darkAccentInk = Color(0xFF3B1826);
  static const Color darkAccentSoft = Color(0xFF33222A);
  static const Color darkGold = Color(0xFFE3B04B);
  static const Color darkGoldInk = Color(0xFFEBD293);
  static const Color darkGoldSoft = Color(0xFF352E1B);
  static const Color darkMiss = Color(0xFFE39A88);
  static const Color darkMissSoft = Color(0xFF3A2420);

  static const Color darkPastelSky = Color(0xFF1E3240);
  static const Color darkPastelSkyInk = Color(0xFF9BCEEB);
  static const Color darkPastelLavender = Color(0xFF2C253A);
  static const Color darkPastelLavenderInk = Color(0xFFC9B9EA);
  static const Color darkPastelBlush = Color(0xFF3A222C);
  static const Color darkPastelBlushInk = Color(0xFFF6C4D7);
  static const Color darkPastelPeach = Color(0xFF3A281E);
  static const Color darkPastelPeachInk = Color(0xFFEBBFA5);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static AppPaletteColors? _ext(BuildContext context) =>
      Theme.of(context).extension<AppPaletteColors>();

  static Color bg(BuildContext context) =>
      _ext(context)?.bg ?? (isDark(context) ? darkBg : lightBg);
  static Color surface(BuildContext context) =>
      _ext(context)?.surface ?? (isDark(context) ? darkSurface : lightSurface);
  static Color soft(BuildContext context) =>
      _ext(context)?.soft ?? (isDark(context) ? darkBg : const Color(0xFFFFF7FA));
  static Color ink(BuildContext context) =>
      _ext(context)?.ink ?? (isDark(context) ? darkInk : lightInk);
  static Color muted(BuildContext context) =>
      _ext(context)?.muted ?? (isDark(context) ? darkMuted : lightMuted);
  static Color line(BuildContext context) =>
      _ext(context)?.line ?? (isDark(context) ? darkLine : lightLine);
  static Color boxLine(BuildContext context) => isDark(context) ? darkBoxLine : lightBoxLine;
  static Color tabBg(BuildContext context) =>
      _ext(context)?.tabBg ?? (isDark(context) ? darkTabBg : lightTabBg);
  static Color accent(BuildContext context) =>
      _ext(context)?.accent ?? (isDark(context) ? darkAccent : lightAccent);
  static Color accentDeep(BuildContext context) =>
      _ext(context)?.accentDeep ?? (isDark(context) ? darkAccentDeep : lightAccentDeep);
  static Color accentInk(BuildContext context) =>
      _ext(context)?.accentInk ?? (isDark(context) ? darkAccentInk : lightAccentInk);
  static Color accentSoft(BuildContext context) =>
      _ext(context)?.accentSoft ?? (isDark(context) ? darkAccentSoft : lightAccentSoft);
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
