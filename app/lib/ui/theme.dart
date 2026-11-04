import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// "Neri": warm paper, glossy round surfaces with soft shadows, an orange
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

/// Soft edges every raised thing shares: a light rim and a warm, blurred
/// shadow. (Was an ink outline with a hard shadow; the glossy redesign keeps
/// the outline only on the characters.)
class Ink2 {
  static const border = BorderSide(color: Color(0xE6FFFFFF), width: 1.5);
  static List<BoxShadow> shadow([double dx = 0, double dy = 8]) => Gloss.soft(dy);
}

/// The glossy material: candy gradients, a shine on top, colored glow below.
/// Shapes are always round: circles and stadiums, or big radii for cards.
class Gloss {
  static List<BoxShadow> soft([double lift = 8, Color tint = const Color(0xFF78501E)]) => [
        BoxShadow(
            color: tint.withValues(alpha: .22),
            offset: Offset(0, lift + 2),
            blurRadius: lift * 2.6,
            spreadRadius: -lift * .8),
        BoxShadow(color: tint.withValues(alpha: .08), offset: const Offset(0, 2), blurRadius: 4),
      ];

  static List<BoxShadow> glow(Color c, [double lift = 10]) => [
        BoxShadow(
            color: c.withValues(alpha: .55),
            offset: Offset(0, lift + 2),
            blurRadius: lift * 2.4,
            spreadRadius: -lift * .9),
      ];

  static const pearlGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8EC), Color(0xFFF7EAD2)],
    stops: [0, .8, 1],
  );
  static const candyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF9A5C), AppColors.orange, Color(0xFFDD5216)],
    stops: [0, .55, 1],
  );
  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6F9BFF), AppColors.blue, Color(0xFF2E5BC8)],
    stops: [0, .6, 1],
  );
  static const honeyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE48A), AppColors.gold, Color(0xFFF2A91E)],
    stops: [0, .6, 1],
  );
  static const glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x38FFFFFF), Color(0x14FFFFFF)],
  );

  static const rim = Border.fromBorderSide(Ink2.border);
  static const glassRim =
      Border.fromBorderSide(BorderSide(color: Color(0x4DFFFFFF), width: 1.5));

  static BoxDecoration pearl({BoxShape shape = BoxShape.rectangle, BorderRadius? radius, double lift = 8}) =>
      BoxDecoration(
        gradient: pearlGradient,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius ?? BorderRadius.circular(999),
        border: rim,
        boxShadow: soft(lift),
      );

  static BoxDecoration candy({BoxShape shape = BoxShape.rectangle, BorderRadius? radius}) => BoxDecoration(
        gradient: candyGradient,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius ?? BorderRadius.circular(999),
        border: const Border.fromBorderSide(BorderSide(color: Color(0x40FFFFFF), width: 1.5)),
        boxShadow: glow(AppColors.orange),
      );

  static BoxDecoration sky({BoxShape shape = BoxShape.rectangle, BorderRadius? radius}) => BoxDecoration(
        gradient: skyGradient,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius ?? BorderRadius.circular(999),
        border: const Border.fromBorderSide(BorderSide(color: Color(0x40FFFFFF), width: 1.5)),
        boxShadow: glow(AppColors.blue, 9),
      );

  static BoxDecoration honey({BoxShape shape = BoxShape.rectangle, BorderRadius? radius, double lift = 8}) =>
      BoxDecoration(
        gradient: honeyGradient,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius ?? BorderRadius.circular(999),
        border: const Border.fromBorderSide(BorderSide(color: Color(0x66FFFFFF), width: 1.5)),
        boxShadow: glow(const Color(0xFFF2A91E), lift),
      );

  static BoxDecoration glass({BoxShape shape = BoxShape.rectangle, BorderRadius? radius}) => BoxDecoration(
        gradient: glassGradient,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius ?? BorderRadius.circular(999),
        border: glassRim,
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 14), blurRadius: 30, spreadRadius: -12),
        ],
      );
}

/// A glossy surface: [decoration] plus a soft white shine across the top.
/// Use with one of the [Gloss] decorations.
class GlossBox extends StatelessWidget {
  const GlossBox({
    super.key,
    required this.decoration,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.shine = .55,
  });

  final BoxDecoration decoration;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double shine;

  @override
  Widget build(BuildContext context) {
    final circle = decoration.shape == BoxShape.circle;
    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Stack(
        fit: StackFit.passthrough,
        alignment: alignment ?? AlignmentDirectional.topStart,
        children: [
          if (shine > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(builder: (context, c) {
                  final h = c.maxHeight.isFinite ? c.maxHeight : 60.0;
                  final w = c.maxWidth.isFinite ? c.maxWidth : 200.0;
                  final shineH = (h * .42).clamp(6.0, 38.0);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.only(top: circle ? h * .07 : 3),
                      width: w * (circle ? .62 : .76),
                      height: shineH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: shine),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          if (child != null)
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: alignment != null ? Align(alignment: alignment!, child: child) : child,
            ),
        ],
      ),
    );
  }
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
    const pill = StadiumBorder();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
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
          elevation: 0,
          side: const BorderSide(color: Color(0x1F1E2340), width: 1.5),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x1F1E2340), width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0x1F1E2340), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.orange, width: 2.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.gold,
        side: const BorderSide(color: Color(0x1F1E2340), width: 1.5),
        showCheckmark: false,
        labelStyle: const TextStyle(
            fontFamily: AppText.sans, color: AppColors.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
            fontFamily: AppText.sans, color: AppColors.ink, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.orange : AppColors.paper2),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.orange : AppColors.ink),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(fontFamily: AppText.sans, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        showDragHandle: true,
        dragHandleColor: Color(0x401E2340),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
