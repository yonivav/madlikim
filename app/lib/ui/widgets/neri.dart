import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Neri (נרי), the candle buddy. A glossy, chubby Hanukkah candle with big
/// shiny eyes. Geometry lives in a 200 x 300 design box (y from -20 to 280),
/// identical to the design prototype (docs/design/neri/).
enum NeriMood { calm, happy, excited, sleep, wink }

enum NeriArms { down, wave, up, point }

/// [highlight, base, shade]
enum NeriColor {
  neri(Color(0xFFFFFFFF), Color(0xFFE9F0FF), Color(0xFF9DB4EC)),
  blue(Color(0xFFCFE2FF), Color(0xFF7FB0FF), Color(0xFF3F74E6)),
  yellow(Color(0xFFFFF3C2), Color(0xFFFFD95C), Color(0xFFE8A92A)),
  pink(Color(0xFFFFE0EA), Color(0xFFFFA8C2), Color(0xFFE8668F)),
  mint(Color(0xFFDDFBEF), Color(0xFF86E3C2), Color(0xFF2FB58A)),
  orange(Color(0xFFFFE3CC), Color(0xFFFFB17A), Color(0xFFEE7B3A)),
  purple(Color(0xFFECE3FF), Color(0xFFBBA2FF), Color(0xFF7C5BE6)),
  red(Color(0xFFFFDADA), Color(0xFFFF9090), Color(0xFFE05252)),
  teal(Color(0xFFD6F7FA), Color(0xFF7FDCE6), Color(0xFF2AA9BA));

  const NeriColor(this.hi, this.base, this.shade);
  final Color hi;
  final Color base;
  final Color shade;

  /// The buddy for night n (1..8).
  static NeriColor forNight(int n) => const [
        blue, yellow, pink, mint, orange, purple, red, teal,
      ][(n - 1) % 8];
}

class Neri extends StatefulWidget {
  const Neri({
    super.key,
    this.color = NeriColor.neri,
    this.mood = NeriMood.happy,
    this.arms = NeriArms.down,
    this.lit = false,
    this.glow = 1,
    this.size = 180,
    this.animate = true,
    this.semanticLabel,
  });

  final NeriColor color;
  final NeriMood mood;
  final NeriArms arms;
  final bool lit;
  final double glow;

  /// Width. Height is 1.5 x width.
  final double size;

  /// Small buddies in a row can set this to false to save work.
  final bool animate;
  final String? semanticLabel;

  @override
  State<Neri> createState() => _NeriState();
}

class _NeriState extends State<Neri> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6));
  double _t = 0;
  late final double _phase = math.Random().nextDouble() * 10;
  double? _litAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still || !widget.animate) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(Neri old) {
    super.didUpdateWidget(old);
    // Grow the flame in only when we are animating; otherwise show it at once.
    if (widget.lit && !old.lit && _ticker.isActive) _litAt = _t;
    if (widget.animate != old.animate) didChangeDependencies();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t + _phase;
    final moving = _ticker.isActive;
    // Bob: excited hops, sleep breathes slowly, everyone else sways a little.
    double dy = 0;
    if (moving) {
      dy = switch (widget.mood) {
        NeriMood.excited => -(math.sin(t * 6).abs()) * 7,
        NeriMood.sleep => math.sin(t * 1.6) * 1.5,
        _ => math.sin(t * 2.4) * 2.5,
      };
    }
    // Blink for ~140ms every ~4s.
    final blink = moving &&
        widget.mood != NeriMood.sleep &&
        widget.mood != NeriMood.wink &&
        (t % 4.1) < .14;
    var flameGrow = 1.0;
    if (_litAt != null) {
      flameGrow = Curves.easeOutBack.transform(((_t - _litAt!) / .5).clamp(0.0, 1.0));
    }
    final w = widget.size;
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox(
        width: w,
        height: w * 1.5,
        child: Transform.translate(
          offset: Offset(0, dy * w / 200),
          child: CustomPaint(
            painter: NeriPainter(
              color: widget.color,
              mood: widget.mood,
              arms: widget.arms,
              lit: widget.lit,
              glow: widget.glow,
              t: moving ? t : 0,
              blink: blink,
              flameGrow: flameGrow,
            ),
          ),
        ),
      ),
    );
  }
}

class NeriPainter extends CustomPainter {
  NeriPainter({
    required this.color,
    required this.mood,
    required this.arms,
    required this.lit,
    required this.glow,
    required this.t,
    required this.blink,
    required this.flameGrow,
  });

  final NeriColor color;
  final NeriMood mood;
  final NeriArms arms;
  final bool lit;
  final double glow;
  final double t;
  final bool blink;
  final double flameGrow;

  static const ink = AppColors.ink;
  static const _cheek = Color(0x80FF7FA3);
  static const _tongue = Color(0xFFFF8FAE);

  RadialGradient get _bodyGrad => RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .9,
        colors: [color.hi, color.base, color.shade],
        stops: const [0, .55, 1],
      );
  RadialGradient get _limbGrad => RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .9,
        colors: [color.hi, color.shade],
      );

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 200, size.height / 300);
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, size.height - 300 * s);
    canvas.scale(s);
    canvas.translate(0, 20); // design box starts at y = -20

    final shadeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.shade
      ..strokeWidth = 2.5;
    final white = Paint()..color = Colors.white;

    // Glow behind a lit flame.
    if (lit && flameGrow > 0) {
      final r = 78 * glow * flameGrow;
      final c = const Offset(100, 48);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.flame.withValues(alpha: .6),
            AppColors.flame.withValues(alpha: .16),
            AppColors.flame.withValues(alpha: 0),
          ], stops: const [0, .5, 1])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // Legs and feet.
    for (final x in [72.0, 112.0]) {
      final leg = RRect.fromLTRBR(x, 228, x + 16, 254, const Radius.circular(8));
      canvas.drawRRect(leg, Paint()..shader = _limbGrad.createShader(leg.outerRect));
    }
    for (final x in [78.0, 122.0]) {
      final foot = Rect.fromCenter(center: Offset(x, 257), width: 34, height: 20);
      canvas.drawOval(foot, Paint()..shader = _limbGrad.createShader(foot));
      canvas.drawOval(foot, shadeStroke);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 5, 253), width: 12, height: 6),
          Paint()..color = Colors.white.withValues(alpha: .6));
    }

    // Arms.
    for (final side in [-1.0, 1.0]) {
      _arm(canvas, side);
    }

    // Body.
    final body = Path()
      ..moveTo(52, 112)
      ..quadraticBezierTo(52, 82, 100, 82)
      ..quadraticBezierTo(148, 82, 148, 112)
      ..lineTo(148, 214)
      ..quadraticBezierTo(148, 236, 126, 236)
      ..lineTo(74, 236)
      ..quadraticBezierTo(52, 236, 52, 214)
      ..close();
    canvas.drawPath(body, Paint()..shader = _bodyGrad.createShader(body.getBounds()));

    // Spiral stripes on the lower body.
    canvas.save();
    canvas.clipPath(body);
    final stripe = Paint()
      ..color = color == NeriColor.neri
          ? const Color(0xE64A7DF0)
          : Colors.white.withValues(alpha: .35);
    for (var i = 0; i < 3; i++) {
      final o = i * 22.0;
      canvas.drawPath(
        Path()
          ..moveTo(30, 206 + o)
          ..quadraticBezierTo(100, 186 + o, 170, 178 + o)
          ..lineTo(170, 187 + o)
          ..quadraticBezierTo(100, 195 + o, 30, 215 + o)
          ..close(),
        stripe,
      );
    }
    canvas.restore();
    canvas.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..color = color.shade
      ..strokeWidth = 3);

    // Melted wax rim.
    final rim = Path()
      ..moveTo(56, 108)
      ..quadraticBezierTo(60, 84, 100, 84)
      ..quadraticBezierTo(140, 84, 144, 108)
      ..quadraticBezierTo(138, 116, 132, 108)
      ..quadraticBezierTo(126, 122, 118, 108)
      ..quadraticBezierTo(110, 116, 104, 106)
      ..quadraticBezierTo(96, 122, 88, 108)
      ..quadraticBezierTo(80, 116, 74, 107)
      ..quadraticBezierTo(64, 120, 56, 108)
      ..close();
    canvas.drawPath(rim, Paint()..color = Colors.white.withValues(alpha: .85));

    // Gloss.
    canvas.drawPath(
      Path()
        ..moveTo(62, 120)
        ..quadraticBezierTo(62, 100, 80, 96)
        ..quadraticBezierTo(70, 112, 70, 140)
        ..lineTo(70, 200)
        ..quadraticBezierTo(64, 196, 62, 186)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .55),
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(72, 104), width: 12, height: 8),
        Paint()..color = Colors.white.withValues(alpha: .9));
    canvas.drawPath(
      Path()
        ..moveTo(142, 130)
        ..lineTo(142, 210)
        ..quadraticBezierTo(142, 226, 128, 230),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: .35),
    );

    // Wick.
    canvas.drawPath(
      Path()
        ..moveTo(100, 84)
        ..quadraticBezierTo(97, 74, 101, 64),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5
        ..color = ink,
    );

    if (lit && flameGrow > 0) _flame(canvas);

    _face(canvas, white);
    canvas.restore();
  }

  void _arm(Canvas canvas, double side) {
    final x0 = 100 + side * 46, y0 = 170.0;
    var wave = 0.0;
    if (arms == NeriArms.wave && side > 0) wave = math.sin(t * 7) * 8;
    final Offset end;
    if (arms == NeriArms.up) {
      end = Offset(x0 + side * 22, y0 - 52 + math.sin(t * 6 + side) * 3);
    } else if (arms == NeriArms.wave && side > 0) {
      end = Offset(x0 + side * 26 + wave * .4, y0 - 44 + wave);
    } else if (arms == NeriArms.point && side < 0) {
      end = Offset(x0 + side * 34, y0 - 14);
    } else {
      end = Offset(x0 + side * 14, y0 + 30);
    }
    final c = Offset(x0 + side * 20, (y0 + end.dy) / 2 + (end.dy < y0 ? 6 : -4));
    final path = Path()
      ..moveTo(x0, y0)
      ..quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..color = color.shade);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = color.base);
    final hand = Rect.fromCircle(center: end, radius: 10);
    canvas.drawOval(hand, Paint()..shader = _limbGrad.createShader(hand));
    canvas.drawOval(hand, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.shade);
    canvas.drawCircle(end - const Offset(3, 3), 3, Paint()..color = Colors.white.withValues(alpha: .7));
  }

  void _flame(Canvas canvas) {
    final g = flameGrow;
    final flick = 1 + .05 * math.sin(t * 9) + .03 * math.sin(t * 23);
    final sway = (math.sin(t * 3.1) * 4 + math.sin(t * 7.3) * 2);
    canvas.save();
    canvas.translate(101, 70);
    canvas.scale(g, g * flick);
    canvas.translate(-101, -70);
    final tip = Offset(101 + sway, -8);
    final outer = Path()
      ..moveTo(101, 70)
      ..cubicTo(70, 52, 78 + sway * .5, 22, tip.dx, tip.dy)
      ..cubicTo(124 + sway * .5, 22, 132, 52, 101, 70)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.flameCore, AppColors.flame, AppColors.ember],
          stops: [0, .42, 1],
        ).createShader(outer.getBounds()),
    );
    canvas.drawPath(
      Path()
        ..moveTo(101, 66)
        ..cubicTo(90, 58, 92, 44, 101 + sway * .3, 32)
        ..cubicTo(110, 44, 112, 58, 101, 66)
        ..close(),
      Paint()..color = AppColors.flameCore.withValues(alpha: .9),
    );
    canvas.save();
    canvas.translate(92, 20);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 16),
        Paint()..color = Colors.white.withValues(alpha: .5));
    canvas.restore();
    canvas.restore();
  }

  void _face(Canvas canvas, Paint white) {
    const ey = 148.0, lx = 80.0, rx = 120.0;
    final inkStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ink;

    void eye(double x, bool big) {
      final w = big ? 13.0 : 11.0, h = big ? 16.0 : 14.0;
      final r = Rect.fromCenter(center: Offset(x, ey), width: w * 2, height: h * 2);
      canvas.drawOval(
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, .5),
            radius: .7,
            colors: [Color(0xFF4C8DFF), Color(0xFF22306E), ink],
            stops: [0, .55, 1],
          ).createShader(r),
      );
      canvas.drawCircle(Offset(x + 4, ey - 6), big ? 5 : 4.2, white);
      canvas.drawCircle(Offset(x - 4, ey + 6), 2, Paint()..color = Colors.white.withValues(alpha: .8));
    }

    void closed(double x) => canvas.drawPath(
        Path()
          ..moveTo(x - 9, ey - 2)
          ..quadraticBezierTo(x, ey + 8, x + 9, ey - 2),
        inkStroke..strokeWidth = 4.5);
    void smiling(double x) => canvas.drawPath(
        Path()
          ..moveTo(x - 9, ey + 4)
          ..quadraticBezierTo(x, ey - 8, x + 9, ey + 4),
        inkStroke..strokeWidth = 4.5);

    final effective = blink ? NeriMood.sleep : mood;
    switch (effective) {
      case NeriMood.sleep:
        closed(lx);
        closed(rx);
      case NeriMood.wink:
        eye(lx, false);
        smiling(rx);
      case NeriMood.excited:
        eye(lx, true);
        eye(rx, true);
      default:
        eye(lx, false);
        eye(rx, false);
    }

    if (mood != NeriMood.sleep) {
      final lift = mood == NeriMood.excited ? -6.0 : 0.0;
      inkStroke.strokeWidth = 3.5;
      canvas.drawPath(
          Path()
            ..moveTo(lx - 9, ey - 22 + lift)
            ..quadraticBezierTo(lx, ey - 28 + lift, lx + 8, ey - 23 + lift),
          inkStroke);
      canvas.drawPath(
          Path()
            ..moveTo(rx - 8, ey - 23 + lift)
            ..quadraticBezierTo(rx, ey - 28 + lift, rx + 9, ey - 22 + lift),
          inkStroke);
    }

    final cheek = Paint()..color = _cheek;
    canvas.drawOval(Rect.fromCenter(center: const Offset(64, ey + 20), width: 22, height: 14), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(136, ey + 20), width: 22, height: 14), cheek);

    const my = ey + 22;
    switch (mood) {
      case NeriMood.sleep:
        canvas.drawOval(Rect.fromCenter(center: const Offset(100, my + 2), width: 10, height: 8),
            Paint()..color = ink);
        _zzz(canvas);
      case NeriMood.calm:
        canvas.drawPath(
            Path()
              ..moveTo(90, my)
              ..quadraticBezierTo(100, my + 9, 110, my),
            inkStroke..strokeWidth = 4);
      default:
        final w = mood == NeriMood.excited ? 15.0 : 12.0;
        final d = mood == NeriMood.excited ? 18.0 : 14.0;
        canvas.drawPath(
          Path()
            ..moveTo(100 - w, my - 2)
            ..quadraticBezierTo(100, my + 2, 100 + w, my - 2)
            ..quadraticBezierTo(100 + w - 2, my + d, 100, my + d)
            ..quadraticBezierTo(100 - w + 2, my + d, 100 - w, my - 2)
            ..close(),
          Paint()..color = ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(100 - w + 5, my + d - 5)
            ..quadraticBezierTo(100, my + d - 12, 100 + w - 5, my + d - 5)
            ..quadraticBezierTo(100 + w - 8, my + d, 100, my + d)
            ..quadraticBezierTo(100 - w + 8, my + d, 100 - w + 5, my + d - 5)
            ..close(),
          Paint()..color = _tongue,
        );
    }
  }

  void _zzz(Canvas canvas) {
    for (final (i, size, x, y) in [(0, 26.0, 150.0, 70.0), (1, 18.0, 166.0, 46.0)]) {
      final drift = (t * .5 + i * .5) % 1.0;
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontFamily: AppText.round,
            fontWeight: FontWeight.w700,
            fontSize: size,
            color: ink.withValues(alpha: (t == 0 ? .55 : (1 - drift) * .6)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + drift * 6, y - 24 - drift * 14));
    }
  }

  @override
  bool shouldRepaint(NeriPainter old) => true;
}
