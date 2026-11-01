import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// "The window": a lit hanukkiah seen from a winter street (Vision, ch. 14).
///
/// Two warm accents on night blue: brass for the menorah and every primary
/// action, olive (the oil of the miracle) for "done" and earned things.
class AppColors {
  static const sky = Color(0xFF101B33);
  static const skyDeep = Color(0xFF0A1226);
  static const glass = Color(0xFF1B2A4A);
  static const glassHi = Color(0xFF24365C);
  static const sill = Color(0xFF2A3A5E);

  static const brass = Color(0xFFD9A441);
  static const brassHi = Color(0xFFF2C66B);
  static const brassLo = Color(0xFF9C6F22);
  static const brassDeep = Color(0xFF8E621C);

  static const flame = Color(0xFFFFC861);
  static const flameCore = Color(0xFFFFF6D6);
  static const ember = Color(0xFFF07F3C);
  static const olive = Color(0xFF9DAA6A);

  static const parch = Color(0xFFF3E9D7);
  static const mist = Color(0xFF9AA6BF);
  static const ink = Color(0xFF1A1206);
  static const line = Color(0x1AF3E9D7);

  static const wax = Color(0xFFFFF9EE);
  static const waxShade = Color(0xFFD8C8AC);
}

/// Type scale: Frank Ruhl Libre for anything read like a book (titles,
/// blessings, songs), Heebo for the interface.
class AppText {
  static const serif = 'FrankRuhlLibre';
  static const sans = 'Heebo';

  /// The night as a Hebrew numeral (ד׳). The one loud element.
  static const numeral = TextStyle(
    fontFamily: serif,
    fontSize: 104,
    height: 0.9,
    fontWeight: FontWeight.w700,
    color: AppColors.brass,
    shadows: [Shadow(color: Color(0x40F2C66B), blurRadius: 30)],
  );

  static const display = TextStyle(
      fontFamily: serif, fontSize: 34, height: 1.1, fontWeight: FontWeight.w700);
  static const title = TextStyle(
      fontFamily: serif, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700);
  static const heading = TextStyle(
      fontFamily: sans, fontSize: 17, height: 1.3, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontFamily: sans, fontSize: 16, height: 1.45);
  static const small =
      TextStyle(fontFamily: sans, fontSize: 14, height: 1.4, color: AppColors.mist);

  /// Blessings and songs: large, roomy, with nikud room.
  static const prayer = TextStyle(
      fontFamily: serif, fontSize: 25, height: 1.75, fontWeight: FontWeight.w500);
  static const lyric = TextStyle(
      fontFamily: serif, fontSize: 21, height: 1.35, fontWeight: FontWeight.w500);
  static const chord = TextStyle(
      fontFamily: sans,
      fontSize: 13.5,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: AppColors.brass);
}

class AppTheme {
  /// Backwards-compatible names used across the screens.
  static const bodyFont = AppText.sans;
  static const blessingFont = AppText.serif;

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppText.sans,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brass,
        onPrimary: AppColors.ink,
        secondary: AppColors.olive,
        onSecondary: AppColors.ink,
        surface: AppColors.sky,
        onSurface: AppColors.parch,
        surfaceContainerHighest: AppColors.glass,
        surfaceContainerHigh: AppColors.glass,
        surfaceContainer: AppColors.sky,
        outline: AppColors.mist,
        error: AppColors.ember,
      ),
      scaffoldBackgroundColor: AppColors.sky,
      splashFactory: InkRipple.splashFactory,
    );
    final rounded16 =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return base.copyWith(
      textTheme: base.textTheme.apply(
          bodyColor: AppColors.parch, displayColor: AppColors.parch),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.parch,
        titleTextStyle: TextStyle(
            fontFamily: AppText.serif,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.parch),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glass,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.glass,
          disabledForegroundColor: AppColors.mist,
          minimumSize: const Size.fromHeight(58),
          textStyle: const TextStyle(
              fontFamily: AppText.sans, fontSize: 19, fontWeight: FontWeight.w800),
          shape: rounded16,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.parch,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0x38F3E9D7)),
          textStyle: const TextStyle(
              fontFamily: AppText.sans, fontSize: 16, fontWeight: FontWeight.w600),
          shape: rounded16,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brass,
          textStyle: const TextStyle(
              fontFamily: AppText.sans, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glass,
        hintStyle: const TextStyle(color: AppColors.mist),
        counterStyle: const TextStyle(color: AppColors.mist),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brass, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.glass,
        selectedColor: AppColors.brass,
        side: BorderSide.none,
        showCheckmark: false,
        labelStyle: const TextStyle(fontFamily: AppText.sans, color: AppColors.parch),
        secondaryLabelStyle: const TextStyle(
            fontFamily: AppText.sans,
            color: AppColors.ink,
            fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ink : AppColors.mist),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.olive : AppColors.sill),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.brass : AppColors.mist),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.glassHi,
        contentTextStyle: TextStyle(fontFamily: AppText.sans, color: AppColors.parch),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sky,
        showDragHandle: true,
        dragHandleColor: AppColors.sill,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
