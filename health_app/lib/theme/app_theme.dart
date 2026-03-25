import 'package:flutter/material.dart';

/// HealthBar Design System
/// Einzigartiges Biolumineszenz-Glassmorphism Design
class AppTheme {
  // ── Farb-Palette ────────────────────────────────────────────
  static const Color bg         = Color(0xFF050B18);   // Tiefes Nachtblau
  static const Color bgCard     = Color(0xFF0D1B2E);   // Karten-Hintergrund
  static const Color bgSurface  = Color(0xFF0F2235);   // Oberflächen

  static const Color neon       = Color(0xFF00E5CC);   // Bio-Türkis (Haupt-Akzent)
  static const Color neonBlue   = Color(0xFF4FC3F7);   // Medizinblau
  static const Color neonGreen  = Color(0xFF69FF94);   // Puls-Grün
  static const Color neonPurple = Color(0xFFCE93D8);   // Neural-Violett

  static const Color textPrimary   = Color(0xFFECF0F1);  // Haupt-Text
  static const Color textSecondary = Color(0xFF7F8C8D);  // Sekundär-Text
  static const Color textMuted     = Color(0xFF4A5568);  // Gedämpft

  static const Color glassWhite    = Color(0x0DFFFFFF);  // Glas-Weiß (5%)
  static const Color glassBorder   = Color(0x1AFFFFFF);  // Glas-Rand (10%)
  static const Color glassWhite20  = Color(0x33FFFFFF);  // Glas-Weiß (20%)

  // Modul-Farben
  static const Color colorBmi      = Color(0xFF00E5CC);
  static const Color colorWater    = Color(0xFF4FC3F7);
  static const Color colorActivity = Color(0xFFFF7043);
  static const Color colorSleep    = Color(0xFFAB47BC);
  static const Color colorFood     = Color(0xFFEF5350);
  static const Color colorAI       = Color(0xFF5C6BC0);
  static const Color colorFace     = Color(0xFF26A69A);
  static const Color colorSymptom  = Color(0xFFEC407A);
  static const Color colorScore    = Color(0xFF66BB6A);
  static const Color colorResearch = Color(0xFFFFCA28);
  static const Color colorVitals   = Color(0xFFFF4081);  // Vitalzeichen-Pink
  static const Color colorMeds     = Color(0xFF7E57C2);  // Medikamenten-Violett
  static const Color colorReport   = Color(0xFF26C6DA);  // Bericht-Türkis
  static const Color colorEmergency = Color(0xFFFF1744); // Notfall-Rot

  // ── Radien ──────────────────────────────────────────────────
  static const double radiusSmall  = 12;
  static const double radiusMid    = 18;
  static const double radiusLarge  = 24;
  static const double radiusXL     = 32;

  // ── Glow-Box-Shadows ────────────────────────────────────────
  static List<BoxShadow> glow(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.4),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ── Gradienten ──────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF050B18), Color(0xFF0A1628), Color(0xFF050B18)],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient neonGradient(Color color) => LinearGradient(
    colors: [color, color.withOpacity(0.6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5CC), Color(0xFF4FC3F7), Color(0xFF5C6BC0)],
  );

  // ── Text-Styles ─────────────────────────────────────────────
  static const TextStyle headline1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: textSecondary, height: 1.5,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: textMuted, letterSpacing: 0.4,
  );
  static const TextStyle neonLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: neon, letterSpacing: 1.5,
  );

  // ── Flutter ThemeData ────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: neon,
      secondary: neonBlue,
      surface: bgCard,
      background: bg,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
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
        backgroundColor: neon,
        foregroundColor: bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMid)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15),
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
        borderSide: const BorderSide(color: neon, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textSecondary),
    ),
  );
}
