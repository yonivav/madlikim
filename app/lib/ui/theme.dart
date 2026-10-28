import 'package:flutter/material.dart';

/// Winter evening, warm home, candlelight (Vision, chapter 14).
class AppColors {
  static const night = Color(0xFF0E1A2B);
  static const nightDeep = Color(0xFF08111E);
  static const nightCard = Color(0xFF16263D);
  static const gold = Color(0xFFF5B942);
  static const flame = Color(0xFFF08A4B);
  static const cream = Color(0xFFFFF6E5);
  static const creamCard = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2A2118);
  static const muted = Color(0xFF8A94A6);
  static const silver = Color(0xFFC9CED8);
}

class AppTheme {
  static const bodyFont = 'Heebo';
  static const blessingFont = 'FrankRuhlLibre';

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: bodyFont,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.nightDeep,
        secondary: AppColors.flame,
        surface: AppColors.night,
        onSurface: AppColors.cream,
        surfaceContainerHighest: AppColors.nightCard,
      ),
      scaffoldBackgroundColor: AppColors.night,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.cream,
      ),
      cardTheme: CardThemeData(
        color: AppColors.nightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.nightDeep,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
              fontFamily: bodyFont, fontSize: 18, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cream,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.muted),
          textStyle: const TextStyle(
              fontFamily: bodyFont, fontSize: 16, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.nightCard,
        selectedColor: AppColors.gold,
        labelStyle: const TextStyle(fontFamily: bodyFont),
        secondaryLabelStyle:
            const TextStyle(fontFamily: bodyFont, color: AppColors.nightDeep),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
