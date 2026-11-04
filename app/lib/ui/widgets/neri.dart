import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// The candle characters. Geometry lives in a 200 x 300 design box
/// (y from -20 to 280), identical to the prototype in docs/design/neri/.
enum NeriMood { calm, happy, excited, sleep, wink }

enum NeriArms { down, wave, up, point }

/// Wax colors: [highlight, base, shade].
enum NeriColor {
  apricot(Color(0xFFFFF1E2), Color(0xFFFFBE85), Color(0xFFEE8746)),
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

  /// The buddy color for night n (1..8).
  static NeriColor forNight(int n) => const [
        blue, yellow, pink, mint, orange, purple, red, teal,
      ][(n - 1) % 8];
}

/// Body shapes. L, R: sides. T: shoulder line. ex/es: eye offset and
/// scale. legs: leg offset from center. round: how domed the top is.
enum NeriBuild {
  classic(52, 148, 82, 20, 1, 20, 30),
  slim(64, 136, 64, 17, .92, 15, 26),
  chubby(42, 158, 100, 23, 1.06, 25, 38);

  const NeriBuild(this.l, this.r, this.t, this.ex, this.es, this.legs, this.round);
  final double l, r, t, ex, es, legs, round;
}

enum NeriPattern { none, stripes, dots, stars }

class NeriLook {
  const NeriLook(this.color, {this.build = NeriBuild.classic, this.pattern = NeriPattern.stripes});
  final NeriColor color;
  final NeriBuild build;
  final NeriPattern pattern;
}

/// A character the user can pick (Vision: "בחרו את הנר שלכם").
class NeriCharacter {
  const NeriCharacter({
    required this.id,
    required this.name,
    required this.line,
    required this.look,
    this.feminine = false,
  });

  final String id;
  final String name;

  /// One-line personality shown in the picker.
  final String line;
  final NeriLook look;

  /// Picks the grammatical gender of the character's lines.
  final bool feminine;

  static const all = <NeriCharacter>[
    NeriCharacter(
        id: 'neri',
        name: 'נרי',
        line: 'הקלאסי. חם ופשוט',
        look: NeriLook(NeriColor.apricot, pattern: NeriPattern.none)),
    NeriCharacter(
        id: 'tchelet',
        name: 'תכלת',
        line: 'כחול־לבן, כמו בחנוכייה של סבתא',
        feminine: true,
        look: NeriLook(NeriColor.neri, pattern: NeriPattern.stripes)),
    NeriCharacter(
        id: 'pazit',
        name: 'פזית',
        line: 'עגלגלה ונוצצת',
        feminine: true,
        look: NeriLook(NeriColor.yellow, build: NeriBuild.chubby, pattern: NeriPattern.stars)),
    NeriCharacter(
        id: 'shoshi',
        name: 'שושי',
        line: 'גבוהה, דקה ומנוקדת',
        feminine: true,
        look: NeriLook(NeriColor.pink, build: NeriBuild.slim, pattern: NeriPattern.dots)),
    NeriCharacter(
        id: 'menti',
        name: 'מנטי',
        line: 'רגוע וקריר',
        look: NeriLook(NeriColor.mint, build: NeriBuild.chubby, pattern: NeriPattern.stripes)),
    NeriCharacter(
        id: 'sigali',
        name: 'סגלי',
        line: 'חולמני, אוהב כוכבים',
        look: NeriLook(NeriColor.purple, build: NeriBuild.slim, pattern: NeriPattern.stars)),
  ];

  static NeriCharacter byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}

class Neri extends StatefulWidget {
  const Neri({
    super.key,
    this.look,
    this.color = NeriColor.apricot,
    this.mood = NeriMood.happy,
    this.arms = NeriArms.down,
    this.lit = false,
    this.glow = 1,
    this.size = 180,
    this.animate = true,
    this.semanticLabel,
  });

  /// Full look. When null, [color] with the classic striped build.
  final NeriLook? look;
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
    _syncTicker();
  }

  void _syncTicker() {
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
    // Grow the flame in only when animating; otherwise show it at once.
    if (widget.lit && !old.lit && _ticker.isActive) _litAt = _t;
    if (widget.animate != old.animate) _syncTicker();
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
    double dy = 0;
    if (moving) {
      dy = switch (widget.mood) {
        NeriMood.excited => -(math.sin(t * 6).abs()) * 7,
        NeriMood.sleep => math.sin(t * 1.6) * 1.5,
        _ => math.sin(t * 2.4) * 2.5,
      };
    }
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
              look: widget.look ?? NeriLook(widget.color),
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
    required this.look,
    required this.mood,
    required this.arms,
    required this.lit,
    required this.glow,
    required this.t,
    required this.blink,
    required this.flameGrow,
  });

  final NeriLook look;
  final NeriMood mood;
  final NeriArms arms;
  final bool lit;
  final double glow;
  final double t;
  final bool blink;
  final double flameGrow;

  static const ink = AppColors.ink;
  static const _cheek = Color(0x80FF6F96);
  static const _tongue = Color(0xFFFF8FAE);
  static const cx = 100.0, bottom = 236.0;

  NeriColor get c => look.color;
  NeriBuild get b => look.build;
  double get hw => (b.r - b.l) / 2;

  RadialGradient get _bodyGrad => RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .9,
        colors: [c.hi, c.base, c.shade],
        stops: const [0, .55, 1],
      );
  RadialGradient get _limbGrad => RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .9,
        colors: [c.hi, c.shade],
      );

  Path get _body {
    final l = b.l, r = b.r, t = b.t;
    return Path()
      ..moveTo(l, t + b.round)
      ..quadraticBezierTo(l, t, cx, t)
      ..quadraticBezierTo(r, t, r, t + b.round)
      ..lineTo(r, bottom - 22)
      ..quadraticBezierTo(r, bottom, r - 22, bottom)
      ..lineTo(l + 22, bottom)
      ..quadraticBezierTo(l, bottom, l, bottom - 22)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 200, size.height / 300);
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, size.height - 300 * s);
    canvas.scale(s);
    canvas.translate(0, 20); // the design box starts at y = -20

    final shadeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = c.shade
      ..strokeWidth = 2.5;
    final top = b.t;

    // Glow behind a lit flame.
    if (lit && flameGrow > 0) {
      final r = 78 * glow * flameGrow;
      final center = Offset(cx, top - 34);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.flame.withValues(alpha: .6),
            AppColors.flame.withValues(alpha: .16),
            AppColors.flame.withValues(alpha: 0),
          ], stops: const [0, .5, 1])
              .createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // Legs and feet.
    for (final side in [-1.0, 1.0]) {
      final x = cx + side * b.legs;
      final leg = RRect.fromLTRBR(x - 8, bottom - 8, x + 8, bottom + 18, const Radius.circular(8));
      canvas.drawRRect(leg, Paint()..shader = _limbGrad.createShader(leg.outerRect));
      final fx = x + 2 * side;
      final foot = Rect.fromCenter(center: Offset(fx, 257), width: 34, height: 20);
      canvas.drawOval(foot, Paint()..shader = _limbGrad.createShader(foot));
      canvas.drawOval(foot, shadeStroke);
      canvas.drawOval(Rect.fromCenter(center: Offset(fx - 5, 253), width: 12, height: 6),
          Paint()..color = Colors.white.withValues(alpha: .6));
    }

    for (final side in [-1.0, 1.0]) {
      _arm(canvas, side);
    }

    final body = _body;
    canvas.drawPath(body, Paint()..shader = _bodyGrad.createShader(body.getBounds()));
    _pattern(canvas, body);
    canvas.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..color = c.shade
      ..strokeWidth = 3);

    // Melted rim with drips.
    final l = b.l, r = b.r;
    final rim = Path()
      ..moveTo(l + 4, top + 26)
      ..quadraticBezierTo(l + 8, top + 2, cx, top + 2)
      ..quadraticBezierTo(r - 8, top + 2, r - 4, top + 26);
    const n = 6;
    final span = r - l - 8;
    for (var i = 1; i <= n; i++) {
      final x1 = r - 4 - span * i / n;
      final xm = x1 + span / n / 2;
      rim.quadraticBezierTo(xm, top + (i.isOdd ? 40 : 34), x1, top + 26 - (i.isOdd ? 0 : 2));
    }
    rim.close();
    canvas.drawPath(rim, Paint()..color = Colors.white.withValues(alpha: .8));

    // Gloss.
    canvas.drawPath(
      Path()
        ..moveTo(l + 10, top + 38)
        ..quadraticBezierTo(l + 10, top + 18, l + 28, top + 14)
        ..quadraticBezierTo(l + 18, top + 30, l + 18, top + 58)
        ..lineTo(l + 18, bottom - 36)
        ..quadraticBezierTo(l + 12, bottom - 40, l + 10, bottom - 50)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .5),
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(l + 20, top + 22), width: 12, height: 8),
        Paint()..color = Colors.white.withValues(alpha: .9));
    canvas.drawPath(
      Path()
        ..moveTo(r - 6, top + 48)
        ..lineTo(r - 6, bottom - 26)
        ..quadraticBezierTo(r - 6, bottom - 10, r - 20, bottom - 6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: .35),
    );

    // Wick.
    canvas.drawPath(
      Path()
        ..moveTo(cx, top + 2)
        ..quadraticBezierTo(cx - 3, top - 8, cx + 1, top - 18),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5
        ..color = ink,
    );

    if (lit && flameGrow > 0) _flame(canvas);
    _face(canvas);
    canvas.restore();
  }

  void _pattern(Canvas canvas, Path body) {
    if (look.pattern == NeriPattern.none) return;
    final light = c == NeriColor.neri;
    final pale = c == NeriColor.yellow;
    final color = light
        ? const Color(0xE64A7DF0)
        : pale
            ? c.shade.withValues(alpha: .75)
            : Colors.white.withValues(alpha: .42);
    final paint = Paint()..color = color;
    final l = b.l, r = b.r, ey = b.t + 66;
    canvas.save();
    canvas.clipPath(body);
    switch (look.pattern) {
      case NeriPattern.stripes:
        for (var i = 0; i < 3; i++) {
          final o = i * 22.0;
          canvas.drawPath(
            Path()
              ..moveTo(l - 22, bottom - 30 + o)
              ..quadraticBezierTo(cx, bottom - 50 + o, r + 22, bottom - 58 + o)
              ..lineTo(r + 22, bottom - 49 + o)
              ..quadraticBezierTo(cx, bottom - 41 + o, l - 22, bottom - 21 + o)
              ..close(),
            paint,
          );
        }
      case NeriPattern.dots:
        var row = 0;
        for (var y = ey + 44; y < bottom - 4; y += 17, row++) {
          for (var x = l + 10 + (row.isOdd ? 10 : 0); x < r - 4; x += 20) {
            canvas.drawCircle(Offset(x, y), 4.5, paint);
          }
        }
      case NeriPattern.stars:
        for (final (x, y, s) in [
          (l + 16, ey + 50, 8.0), (cx + 6, ey + 66, 10.0), (r - 16, ey + 46, 7.0),
          (l + 26, bottom - 16, 6.0), (r - 22, bottom - 20, 9.0),
          (l + 14, b.t + 40, 5.0), (r - 12, b.t + 34, 6.0),
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, y - s)
              ..quadraticBezierTo(x + s * .22, y - s * .22, x + s, y)
              ..quadraticBezierTo(x + s * .22, y + s * .22, x, y + s)
              ..quadraticBezierTo(x - s * .22, y + s * .22, x - s, y)
              ..quadraticBezierTo(x - s * .22, y - s * .22, x, y - s)
              ..close(),
            paint,
          );
        }
      case NeriPattern.none:
        break;
    }
    canvas.restore();
  }

  void _arm(Canvas canvas, double side) {
    final x0 = cx + side * (hw - 2), y0 = b.t + 88;
    final wave = arms == NeriArms.wave && side > 0 ? math.sin(t * 7) * 8 : 0.0;
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
    final ctrl = Offset(x0 + side * 20, (y0 + end.dy) / 2 + (end.dy < y0 ? 6 : -4));
    final path = Path()
      ..moveTo(x0, y0)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..color = c.shade);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = c.base);
    final hand = Rect.fromCircle(center: end, radius: 10);
    canvas.drawOval(hand, Paint()..shader = _limbGrad.createShader(hand));
    canvas.drawOval(hand, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = c.shade);
    canvas.drawCircle(end - const Offset(3, 3), 3, Paint()..color = Colors.white.withValues(alpha: .7));
  }

  void _flame(Canvas canvas) {
    final g = flameGrow;
    final f = b.t - 12;
    final flick = 1 + .05 * math.sin(t * 9) + .03 * math.sin(t * 23);
    final sway = math.sin(t * 3.1) * 4 + math.sin(t * 7.3) * 2;
    canvas.save();
    canvas.translate(cx + 1, f);
    canvas.scale(g, g * flick);
    canvas.translate(-(cx + 1), -f);
    final outer = Path()
      ..moveTo(cx + 1, f)
      ..cubicTo(cx - 30, f - 18, cx - 22 + sway * .5, f - 48, cx + 1 + sway, f - 78)
      ..cubicTo(cx + 24 + sway * .5, f - 48, cx + 32, f - 18, cx + 1, f)
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
        ..moveTo(cx + 1, f - 4)
        ..cubicTo(cx - 10, f - 12, cx - 8, f - 26, cx + 1 + sway * .3, f - 38)
        ..cubicTo(cx + 10, f - 26, cx + 12, f - 12, cx + 1, f - 4)
        ..close(),
      Paint()..color = AppColors.flameCore.withValues(alpha: .9),
    );
    canvas.save();
    canvas.translate(cx - 8, f - 50);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 16),
        Paint()..color = Colors.white.withValues(alpha: .5));
    canvas.restore();
    canvas.restore();
  }

  void _face(Canvas canvas) {
    final ey = b.t + 66, lx = cx - b.ex, rx = cx + b.ex, k = b.es;
    final white = Paint()..color = Colors.white;
    final inkStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ink;

    void eye(double x, bool big) {
      final w = (big ? 13.0 : 11.0) * k, h = (big ? 16.0 : 14.0) * k;
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
      canvas.drawCircle(Offset(x + 4 * k, ey - 6 * k), (big ? 5 : 4.2) * k, white);
      canvas.drawCircle(Offset(x - 4 * k, ey + 6 * k), 2 * k,
          Paint()..color = Colors.white.withValues(alpha: .8));
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

    switch (blink ? NeriMood.sleep : mood) {
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
            ..moveTo(lx - 9, ey - 22 * k + lift)
            ..quadraticBezierTo(lx, ey - 28 * k + lift, lx + 8, ey - 23 * k + lift),
          inkStroke);
      canvas.drawPath(
          Path()
            ..moveTo(rx - 8, ey - 23 * k + lift)
            ..quadraticBezierTo(rx, ey - 28 * k + lift, rx + 9, ey - 22 * k + lift),
          inkStroke);
    }

    final cheek = Paint()..color = _cheek;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - hw + 12, ey + 20), width: 22, height: 14), cheek);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + hw - 12, ey + 20), width: 22, height: 14), cheek);

    final my = ey + 22;
    switch (mood) {
      case NeriMood.sleep:
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 2), width: 10, height: 8),
            Paint()..color = ink);
        _zzz(canvas);
      case NeriMood.calm:
        canvas.drawPath(
            Path()
              ..moveTo(cx - 10, my)
              ..quadraticBezierTo(cx, my + 9, cx + 10, my),
            inkStroke..strokeWidth = 4);
      default:
        final w = mood == NeriMood.excited ? 15.0 : 12.0;
        final d = mood == NeriMood.excited ? 18.0 : 14.0;
        canvas.drawPath(
          Path()
            ..moveTo(cx - w, my - 2)
            ..quadraticBezierTo(cx, my + 2, cx + w, my - 2)
            ..quadraticBezierTo(cx + w - 2, my + d, cx, my + d)
            ..quadraticBezierTo(cx - w + 2, my + d, cx - w, my - 2)
            ..close(),
          Paint()..color = ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx - w + 5, my + d - 5)
            ..quadraticBezierTo(cx, my + d - 12, cx + w - 5, my + d - 5)
            ..quadraticBezierTo(cx + w - 8, my + d, cx, my + d)
            ..quadraticBezierTo(cx - w + 8, my + d, cx - w + 5, my + d - 5)
            ..close(),
          Paint()..color = _tongue,
        );
    }
  }

  void _zzz(Canvas canvas) {
    for (final (i, size, dx, dy) in [(0, 26.0, 2.0, -12.0), (1, 18.0, 18.0, -36.0)]) {
      final drift = (t * .5 + i * .5) % 1.0;
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontFamily: AppText.round,
            fontWeight: FontWeight.w700,
            fontSize: size,
            color: ink.withValues(alpha: t == 0 ? .55 : (1 - drift) * .6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(b.r + dx + drift * 6, b.t + dy - size - drift * 14));
    }
  }

  @override
  bool shouldRepaint(NeriPainter old) => true;
}
