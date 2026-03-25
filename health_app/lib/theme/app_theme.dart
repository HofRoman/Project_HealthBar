import 'package:flutter/material.dart';

/// HealthBar Design System — Professional Medical Edition
/// Klinisches, seriöses Design für medizinische Anwendungen
class AppTheme {
  // ── Hintergrund-Palette ─────────────────────────────────────
  static const Color bg         = Color(0xFF07101E);  // Tiefes Marineblau
  static const Color bgCard     = Color(0xFF0D1926);  // Karten-Hintergrund
  static const Color bgSurface  = Color(0xFF112135);  // Oberflächen-Ebene

  // ── Primär-Akzente (Medizinisch-Blau) ───────────────────────
  static const Color primary    = Color(0xFF2A7DE1);  // Medizinblau
  static const Color primaryDim = Color(0xFF1A5CA8);  // Gedämpft
  static const Color accent     = Color(0xFF10A899);  // Klinisches Türkis

  // ── Semantische Farben ───────────────────────────────────────
  static const Color success    = Color(0xFF1A9B6C);  // Klinisches Grün
  static const Color warning    = Color(0xFFD4820A);  // Bernstein
  static const Color danger     = Color(0xFFB93030);  // Medizinrot
  static const Color info       = Color(0xFF1F6FA3);  // Informationsblau

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFDDE6F0);  // Primärtext
  static const Color textSecondary = Color(0xFF6B8299);  // Sekundärtext
  static const Color textMuted     = Color(0xFF3D5166);  // Gedämpft

  // ── Glas/Border ─────────────────────────────────────────────
  static const Color glassWhite   = Color(0x08FFFFFF);  // 3%
  static const Color glassBorder  = Color(0x0FFFFFFF);  // 6%
  static const Color glassWhite20 = Color(0x14FFFFFF);  // 8%

  // ── Modul-Farben (gedämpft, professionell) ───────────────────
  static const Color colorBmi      = Color(0xFF2A7DE1);  // Blau
  static const Color colorWater    = Color(0xFF1A7EC8);  // Wasserblau
  static const Color colorActivity = Color(0xFFB85B28);  // Terrakotta
  static const Color colorSleep    = Color(0xFF6355A0);  // Dunkellila
  static const Color colorFood     = Color(0xFFA83535);  // Dunkelrot
  static const Color colorAI       = Color(0xFF2952A3);  // Tiefblau
  static const Color colorFace     = Color(0xFF177B6B);  // Dunkeltürkis
  static const Color colorSymptom  = Color(0xFF8C2952);  // Dunkelpink
  static const Color colorScore    = Color(0xFF1A7A52);  // Dunkelgrün
  static const Color colorResearch = Color(0xFF8A7020);  // Dunkelgold
  static const Color colorVitals   = Color(0xFF993060);  // Dunkelrosa
  static const Color colorMeds     = Color(0xFF5B3D99);  // Dunkelviolett
  static const Color colorReport   = Color(0xFF1A6E80);  // Dunkeltürkis
  static const Color colorEmergency= Color(0xFFA82020);  // Dunkelrot

  // ── Radien ──────────────────────────────────────────────────
  static const double radiusSmall = 8;
  static const double radiusMid   = 12;
  static const double radiusLarge = 16;
  static const double radiusXL    = 20;

  // ── Schatten (kein Neon-Glow, nur subtile Tiefe) ────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sehr dezenter farbiger Schatten (nur für aktive Elemente)
  static List<BoxShadow> subtleGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 14,
      spreadRadius: -2,
    ),
  ];

  // Aliase für Abwärtskompatibilität
  static List<BoxShadow> glow(Color color, {double intensity = 0.3}) =>
      subtleGlow(color);

  // ── Gradienten ──────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07101E), Color(0xFF0A1525)],
  );

  static LinearGradient neonGradient(Color color) => LinearGradient(
    colors: [color, color.withOpacity(0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A7DE1), Color(0xFF10A899)],
  );

  // ── Text-Styles ─────────────────────────────────────────────
  static const TextStyle headline1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.2,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: 0.1,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: textSecondary, height: 1.55,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: textMuted, letterSpacing: 0.3,
  );
  static const TextStyle neonLabel = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: primary, letterSpacing: 1.2,
  );
  static const TextStyle monoValue = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: 0.5,
    fontFamily: 'monospace',
  );

  // ── Flutter ThemeData ────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: bgCard,
      background: bg,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: bgCard,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: textPrimary, letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    tabBarTheme: TabBarTheme(
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2),
      ),
      labelColor: primary,
      unselectedLabelColor: textMuted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
    dividerTheme: DividerThemeData(
      color: glassBorder,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      titleLarge: headline2,
      titleMedium: headline3,
      bodyLarge: bodyBold,
      bodyMedium: body,
      labelSmall: caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMid)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMid)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: glassWhite,
      selectedColor: primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      side: const BorderSide(color: glassBorder),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgSurface,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge)),
      titleTextStyle: headline2,
    ),
  );
}
