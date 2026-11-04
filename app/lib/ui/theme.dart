import 'package:flutter/material.dart';

/// "Neri": warm paper, ink outlines with a hard offset shadow, an orange
/// action color, Hanukkah blue, and golden light that rises night by night.
/// Night screens (celebration, Shabbat) switch to deep blue.
class AppColors {
  static const paper = Color(0xFFF6F0E3);
  static const paper2 = Color(0xFFEDE3CD);
  static const card = Color(0xFFFFFDF8);
  static const ink = Color(0xFF1E2340);
  static const muted = Color(0xFF7A7466);
  static const line = Color(0x261E2340);

  static const orange = Color(0xFFF26B2A);
  static const orangeHi = Color(0xFFFF8A4C);
  static const blue = Color(0xFF3F74E6);
  static const gold = Color(0xFFFFC63A);
  static const goldSoft = Color(0xFFFFE7A6);
  static const pink = Color(0xFFFF7FA3);
  static const olive = Color(0xFF5E9C4A);

  static const flame = Color(0xFFFFC63A);
  static const flameCore = Color(0xFFFFF7D1);
  static const ember = Color(0xFFFF6A1F);

  static const night = Color(0xFF1C2463);
  static const nightHi = Color(0xFF3B3A8E);
  static const nightDeep = Color(0xFF121640);
  static const onNight = Color(0xFFF4F1FF);
  static const onNightSoft = Color(0xFFC9C6E8);
}

/// Fredoka (round, playful) for numbers and buttons, Frank Ruhl Libre for
/// titles and anything sacred, Rubik for reading.
class AppText {
  static const round = 'Fredoka';
  static const serif = 'FrankRuhlLibre';
  static const sans = 'Rubik';

  static const numeral = TextStyle(
      fontFamily: round, fontSize: 44, height: 1.05, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const display = TextStyle(
      fontFamily: serif, fontSize: 31, height: 1.1, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const title = TextStyle(
      fontFamily: serif, fontSize: 24, height: 1.15, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const heading = TextStyle(
      fontFamily: sans, fontSize: 16.5, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const body =
      TextStyle(fontFamily: sans, fontSize: 16, height: 1.45, color: AppColors.ink);
  static const small =
      TextStyle(fontFamily: sans, fontSize: 13.5, height: 1.4, color: AppColors.muted);
  static const button = TextStyle(
      fontFamily: round, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white);

  /// Blessings and songs.
  static const prayer = TextStyle(
      fontFamily: serif, fontSize: 23, height: 1.75, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const lyric = TextStyle(
      fontFamily: serif, fontSize: 21, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const chord = TextStyle(
      fontFamily: sans, fontSize: 13.5, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.blue);
}

/// The outline + hard shadow every raised thing shares.
class Ink2 {
  static const border = BorderSide(color: AppColors.ink, width: 2);
  static List<BoxShadow> shadow([double dx = 3, double dy = 3]) =>
      [BoxShadow(color: AppColors.ink, offset: Offset(dx, dy), blurRadius: 0)];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppText.sans,
      colorScheme: const ColorScheme.light(
        primary: AppColors.orange,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.card,
        surfaceContainerHigh: AppColors.card,
        surfaceContainer: AppColors.paper,
        outline: AppColors.ink,
        error: AppColors.ember,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: InkRipple.splashFactory,
    );
    final pill = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), side: Ink2.border);
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
            fontFamily: AppText.serif,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), side: Ink2.border),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.paper2,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(56),
          textStyle: AppText.button,
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.card,
          minimumSize: const Size.fromHeight(52),
          side: Ink2.border,
          textStyle: const TextStyle(
              fontFamily: AppText.round, fontSize: 17, fontWeight: FontWeight.w600),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: const TextStyle(
              fontFamily: AppText.sans, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.muted),
        counterStyle: const TextStyle(color: AppColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: Ink2.border,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: Ink2.border,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 2.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.gold,
        side: Ink2.border,
        showCheckmark: false,
        labelStyle: const TextStyle(
            fontFamily: AppText.sans, color: AppColors.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
            fontFamily: AppText.sans, color: AppColors.ink, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.orange : AppColors.paper2),
        trackOutlineColor: WidgetStateProperty.all(AppColors.ink),
        trackOutlineWidth: WidgetStateProperty.all(2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.orange : AppColors.ink),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(fontFamily: AppText.sans, color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        showDragHandle: true,
        dragHandleColor: AppColors.ink,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
