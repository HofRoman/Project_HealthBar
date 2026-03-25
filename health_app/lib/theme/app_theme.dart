import 'package:flutter/material.dart';

/// HealthBar — Monochrome Design System (Black & White)
class AppTheme {
  // ── Hintergrundfarben ─────────────────────────────────────────
  static const Color bg         = Color(0xFF000000);   // Pure Black
  static const Color bgCard     = Color(0xFF1C1C1E);   // Dark Grey
  static const Color bgSurface  = Color(0xFF2C2C2E);   // Mid Dark Grey
  static const Color bgTertiary = Color(0xFF3A3A3C);   // Light Dark Grey

  // ── Monochrome System Colors ──────────────────────────────────
  static const Color white      = Color(0xFFFFFFFF);
  static const Color grey90     = Color(0xFFE5E5EA);   // Near white
  static const Color grey70     = Color(0xFFAEAEB2);   // Medium grey
  static const Color grey50     = Color(0xFF8E8E93);   // Mid grey
  static const Color grey30     = Color(0xFF48484A);   // Dark grey
  static const Color grey20     = Color(0xFF3A3A3C);   // Very dark grey

  // ── iOS System Colors → Monochrome Aliases ───────────────────
  static const Color iosBlue    = white;
  static const Color iosGreen   = grey90;
  static const Color iosRed     = white;
  static const Color iosOrange  = grey70;
  static const Color iosPurple  = grey70;
  static const Color iosTeal    = grey90;
  static const Color iosIndigo  = grey90;
  static const Color iosPink    = grey90;
  static const Color iosYellow  = grey70;

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAEAEB2);  // grey70
  static const Color textMuted     = Color(0xFF8E8E93);  // grey50
  static const Color separator     = Color(0xFF3A3A3C);  // grey20

  // ── Glas/Fill ────────────────────────────────────────────────
  static const Color glassFill    = Color(0x1AFFFFFF);   // 10% white
  static const Color glassBorder  = Color(0x26FFFFFF);   // 15% white
  static const Color glassWhite   = Color(0x0AFFFFFF);
  static const Color glassWhite20 = Color(0x1AFFFFFF);

  // ── Compatibility Aliases ─────────────────────────────────────
  static const Color primary    = white;
  static const Color accent     = grey90;
  static const Color success    = grey90;
  static const Color warning    = grey70;
  static const Color danger     = white;
  static const Color info       = grey90;
  static const Color neon       = white;
  static const Color neonGreen  = grey90;
  static const Color neonBlue   = white;
  static const Color neonPurple = grey70;

  // ── Modul-Farben → alle grau ──────────────────────────────────
  static const Color colorBmi       = white;
  static const Color colorWater     = grey90;
  static const Color colorActivity  = grey70;
  static const Color colorSleep     = grey70;
  static const Color colorFood      = grey90;
  static const Color colorAI        = white;
  static const Color colorFace      = grey90;
  static const Color colorSymptom   = grey70;
  static const Color colorScore     = white;
  static const Color colorResearch  = grey70;
  static const Color colorVitals    = grey90;
  static const Color colorMeds      = grey70;
  static const Color colorReport    = white;
  static const Color colorEmergency = white;

  // ── Radien ────────────────────────────────────────────────────
  static const double radiusSmall = 10;
  static const double radiusMid   = 14;
  static const double radiusLarge = 20;
  static const double radiusXL    = 28;

  // ── Schatten ─────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtleGlow(Color color) => [
    BoxShadow(
      color: Colors.white.withOpacity(0.05),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glow(Color color, {double intensity = 0.2}) =>
      subtleGlow(color);

  // ── Gradienten ───────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
  );

  static LinearGradient neonGradient(Color color) => const LinearGradient(
    colors: [white, grey90],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, grey90],
  );

  // ── Text-Styles ───────────────────────────────────────────────
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
    color: textSecondary, letterSpacing: 0.5,
  );
  static const TextStyle monoValue = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: textPrimary, letterSpacing: 0.3,
  );

  // ── Flutter ThemeData ─────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: white,
      secondary: grey90,
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
        borderSide: BorderSide(color: white, width: 2),
      ),
      labelColor: white,
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
        backgroundColor: white,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: white,
        side: const BorderSide(color: white, width: 1),
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
        borderSide: const BorderSide(color: white, width: 1.5),
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
