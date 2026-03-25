import 'package:flutter/material.dart';

/// HealthBar — iOS 26 Liquid Glass Design System
class AppTheme {
  // ── Hintergrundfarben (iOS Dark) ─────────────────────────────
  static const Color bg         = Color(0xFF000000);   // Pure Black (OLED)
  static const Color bgCard     = Color(0xFF1C1C1E);   // iOS systemBackground
  static const Color bgSurface  = Color(0xFF2C2C2E);   // iOS secondarySystemBackground
  static const Color bgTertiary = Color(0xFF3A3A3C);   // iOS tertiarySystemBackground

  // ── iOS System Colors ────────────────────────────────────────
  static const Color iosBlue    = Color(0xFF0A84FF);
  static const Color iosGreen   = Color(0xFF30D158);
  static const Color iosRed     = Color(0xFFFF453A);
  static const Color iosOrange  = Color(0xFFFF9F0A);
  static const Color iosPurple  = Color(0xFFBF5AF2);
  static const Color iosTeal    = Color(0xFF40C8E0);
  static const Color iosIndigo  = Color(0xFF5E5CE6);
  static const Color iosPink    = Color(0xFFFF375F);
  static const Color iosYellow  = Color(0xFFFFD60A);

  // ── Text (iOS Standard) ──────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99EBEBF5);  // 60% white
  static const Color textMuted     = Color(0x4DEBEBF5);  // 30% white
  static const Color separator     = Color(0x14545458);  // iOS separator

  // ── Glas/Fill ────────────────────────────────────────────────
  static const Color glassFill    = Color(0x14FFFFFF);   // iOS fill
  static const Color glassBorder  = Color(0x18FFFFFF);   // iOS border
  static const Color glassWhite   = Color(0x0AFFFFFF);
  static const Color glassWhite20 = Color(0x1AFFFFFF);

  // ── Compatibility Aliases (für bestehende Screens) ───────────
  static const Color primary    = iosBlue;
  static const Color accent     = iosTeal;
  static const Color success    = iosGreen;
  static const Color warning    = iosOrange;
  static const Color danger     = iosRed;
  static const Color info       = iosIndigo;
  static const Color neon       = iosTeal;
  static const Color neonGreen  = iosGreen;
  static const Color neonBlue   = iosBlue;
  static const Color neonPurple = iosPurple;

  // ── Modul-Farben ─────────────────────────────────────────────
  static const Color colorBmi       = iosBlue;
  static const Color colorWater     = iosTeal;
  static const Color colorActivity  = iosOrange;
  static const Color colorSleep     = iosPurple;
  static const Color colorFood      = iosRed;
  static const Color colorAI        = iosIndigo;
  static const Color colorFace      = iosTeal;
  static const Color colorSymptom   = iosPink;
  static const Color colorScore     = iosGreen;
  static const Color colorResearch  = iosYellow;
  static const Color colorVitals    = iosPink;
  static const Color colorMeds      = iosPurple;
  static const Color colorReport    = iosTeal;
  static const Color colorEmergency = iosRed;

  // ── Radien (iOS 26 — sehr rund) ──────────────────────────────
  static const double radiusSmall = 10;
  static const double radiusMid   = 14;
  static const double radiusLarge = 20;
  static const double radiusXL    = 28;

  // ── Schatten (iOS — weich, kein Neon) ───────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtleGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.2),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  // Compatibility alias
  static List<BoxShadow> glow(Color color, {double intensity = 0.2}) =>
      subtleGlow(color);

  // ── Gradienten ──────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF0A0A0F)],
  );

  static LinearGradient neonGradient(Color color) => LinearGradient(
    colors: [color, color.withOpacity(0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [iosBlue, iosTeal],
  );

  // ── Text-Styles ─────────────────────────────────────────────
  static const TextStyle headline1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: -0.1,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: textSecondary, height: 1.55,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: textMuted,
  );
  static const TextStyle neonLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: iosBlue, letterSpacing: 0.5,
  );
  static const TextStyle monoValue = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: textPrimary, letterSpacing: 0.3,
  );

  // ── Flutter ThemeData ────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: iosBlue,
      secondary: iosTeal,
      surface: bgCard,
      background: bg,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: iosBlue, width: 2),
      ),
      labelColor: iosBlue,
      unselectedLabelColor: textMuted,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: separator, thickness: 0.5,
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
        backgroundColor: iosBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: iosBlue,
        side: const BorderSide(color: iosBlue, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassFill,
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
        borderSide: const BorderSide(color: iosBlue, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 15),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgSurface,
      contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL)),
      titleTextStyle: headline3,
    ),
  );
}
