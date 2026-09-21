import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jetons de design — Identité visuelle Yam
class YamColors {
  // Vert (Primaire) : Éléments clés et actions principales
  static const primary = Color(0xFF16A34A);
  static const primaryDark = Color(0xFF15803D);
  static const primarySoft = Color(0xFFF0FDF4);
  static const primaryLight = Color(0xFFDCFCE7);

  // Orange (Accent / Secondaire) : Badges, alertes, touches dynamiques
  static const accent = Color(0xFFEA580C);
  static const accentSoft = Color(0xFFFFF7ED);
  static const accentLight = Color(0xFFFFEDD5);

  // Blanc / Gris très clair : Arrière-plans et conteneurs
  static const pageBg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);

  // Textes et statuts
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const accept = Color(0xFF16A34A);

  // Écrans d'appel sombres
  static const callCardTop = Color(0xFF2A2A3A);
  static const callCardBottom = Color(0xFF16161F);
  static const avatarBg = Color(0xFF3A3A4A);
}

const kFieldRadius = BorderRadius.all(Radius.circular(14));
const kButtonRadius = BorderRadius.all(Radius.circular(14));
const kCardRadius = BorderRadius.all(Radius.circular(16));
const kShellRadius = BorderRadius.all(Radius.circular(20));

class YamTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YamColors.pageBg,
      primaryColor: YamColors.primary,
      colorScheme: const ColorScheme.light(
        primary: YamColors.primary,
        secondary: YamColors.accent,
        surface: YamColors.surface,
        error: YamColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: YamColors.text,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: YamColors.text),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: YamColors.text),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: YamColors.text),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YamColors.text),
        bodyLarge: TextStyle(fontSize: 16, color: YamColors.text),
        bodyMedium: TextStyle(fontSize: 14, color: YamColors.text),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: YamColors.surface,
        foregroundColor: YamColors.text,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x10000000),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: YamColors.text,
        ),
        iconTheme: IconThemeData(color: YamColors.text),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: YamColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: YamColors.muted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: kFieldRadius, borderSide: BorderSide(color: YamColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: kFieldRadius, borderSide: BorderSide(color: YamColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: kFieldRadius, borderSide: BorderSide(color: YamColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: kFieldRadius, borderSide: BorderSide(color: YamColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: kFieldRadius, borderSide: BorderSide(color: YamColors.danger, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YamColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: kButtonRadius),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YamColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: kButtonRadius),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YamColors.primary,
          side: const BorderSide(color: YamColors.primary, width: 1.2),
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: kButtonRadius),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: YamColors.primary,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      cardTheme: const CardThemeData(
        color: YamColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: kCardRadius,
          side: BorderSide(color: YamColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: YamColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: YamColors.surface,
        elevation: 8,
        selectedItemColor: YamColors.primary,
        unselectedItemColor: YamColors.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}

/// Style mono pour device IDs, timers et métadonnées techniques.
TextStyle mono({double size = 13, Color color = YamColors.muted}) =>
    TextStyle(fontFamily: 'monospace', fontSize: size, color: color);
