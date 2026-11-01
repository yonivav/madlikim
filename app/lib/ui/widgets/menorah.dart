import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// A brass hanukkiah: eight cups level on one bar and a raised shamash.
///
/// Positions are numbered 0..7 from the RIGHT, where night 1's candle goes.
/// Drawn in a 360x230 design box (same geometry as the design prototype),
/// scaled to fit and anchored to the bottom.
class Menorah extends StatefulWidget {
  const Menorah({
    super.key,
    this.placed = const {},
    this.lit = const {},
    this.shamashLit = false,
    this.orderLabels = const {},
    this.height = 200,
    this.glow = 1.0,
  });

  /// Positions that hold a candle.
  final Set<int> placed;

  /// Positions whose candle is burning.
  final Set<int> lit;
  final bool shamashLit;

  /// Small numbers on the candles (lighting order).
  final Map<int, int> orderLabels;
  final double height;

  /// 0..1, how much the light spills into the room.
  final double glow;

  /// Lighting order for [night] candles: the newest (leftmost) first.
  static Map<int, int> lightingOrder(int night) =>
      {for (var i = 0; i < night; i++) night - 1 - i: i + 1};

  @override
  State<Menorah> createState() => _MenorahState();
}

class _MenorahState extends State<Menorah> with SingleTickerProviderStateMixin {
  static const _shamash = -1;
  static const _igniteMs = 520;

  late final Ticker _ticker;
  Duration _now = Duration.zero;
  final Map<int, Duration> _ignitedAt = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _now = d));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void didUpdateWidget(Menorah old) {
    super.didUpdateWidget(old);
    for (final p in widget.lit.difference(old.lit)) {
      _ignitedAt[p] = _now;
    }
    if (widget.shamashLit && !old.shamashLit) _ignitedAt[_shamash] = _now;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _ignite(int p) {
    final at = _ignitedAt[p];
    if (at == null) return 1;
    final t = ((_now - at).inMilliseconds / _igniteMs).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t).clamp(0.0, 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final burning = widget.lit.length + (widget.shamashLit ? 1 : 0);
    return Semantics(
      label: burning == 0
          ? 'חנוכייה, ${widget.placed.length} נרות מוכנים'
          : 'חנוכייה, $burning נרות דולקים',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: MenorahPainter(
              placed: widget.placed,
              lit: widget.lit,
              shamashLit: widget.shamashLit,
              orderLabels: widget.orderLabels,
              glow: widget.glow,
              t: still ? 0 : _now.inMicroseconds / 1e6,
              ignite: {
                for (final p in widget.lit) p: _ignite(p),
                if (widget.shamashLit) _shamash: _ignite(_shamash),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MenorahPainter extends CustomPainter {
  MenorahPainter({
    required this.placed,
    required this.lit,
    required this.shamashLit,
    required this.orderLabels,
    required this.glow,
    required this.t,
    required this.ignite,
  });

  final Set<int> placed;
  final Set<int> lit;
  final bool shamashLit;
  final Map<int, int> orderLabels;
  final double glow;

  /// Seconds, for the flicker.
  final double t;

  /// Position (-1 = shamash) → 0..1 flame growth.
  final Map<int, double> ignite;

  static const w = 360.0, h = 230.0, cx = 180.0, step = 38.0;
  static const barY = 150.0, cupH = 9.0, shY = barY - 46;

  static double slotX(int i) => cx + (i - 4) * step;
  static double posX(int p) => p <= 3 ? slotX(8 - p) : slotX(7 - p);

  static const _brassV = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brassHi, AppColors.brass, AppColors.brassDeep],
    stops: [0, .5, 1],
  );
  static const _brassH = LinearGradient(
    colors: [AppColors.brassLo, AppColors.brassHi, AppColors.brassLo],
  );
  static const _wax = LinearGradient(
    colors: [Color(0xFFE9DCC4), AppColors.wax, AppColors.waxShade],
    stops: [0, .45, 1],
  );
  static const _flame = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.flameCore, AppColors.flame, AppColors.ember],
    stops: [0, .4, 1],
  );

  Paint _fill(Gradient g, Rect r) => Paint()..shader = g.createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / w, size.height / h);
    canvas.save();
    canvas.translate((size.width - w * scale) / 2, size.height - h * scale);
    canvas.scale(scale);

    // Light spilling into the room.
    final burning = lit.length + (shamashLit ? 1 : 0);
    if (burning > 0 && glow > 0) {
      final strength = math.min(1.0, .25 + burning * .1) * glow;
      final rect = Rect.fromCenter(
          center: const Offset(cx, barY - 40), width: 360, height: 240);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.flame.withValues(alpha: .22 * strength),
            AppColors.flame.withValues(alpha: 0),
          ]).createShader(rect),
      );
    }

    // Base.
    final base = Path()
      ..moveTo(cx - 46, h - 6)
      ..quadraticBezierTo(cx, h - 30, cx + 46, h - 6)
      ..close();
    canvas.drawPath(base, _fill(_brassV, base.getBounds()));
    final foot = RRect.fromLTRBR(cx - 54, h - 8, cx + 54, h - 2, const Radius.circular(3));
    canvas.drawRRect(foot, _fill(_brassH, foot.outerRect));

    // Stem with a knot.
    final stem = Rect.fromLTWH(cx - 4, barY, 8, h - barY - 22);
    canvas.drawRect(stem, _fill(_brassH, stem));
    final knot = Rect.fromCenter(center: const Offset(cx, barY + 34), width: 18, height: 10);
    canvas.drawOval(knot, _fill(_brassV, knot));

    // Arms: two shallow arcs under the bar.
    void arc(double x0, double x1, double depth, double width, double alpha) {
      final p = Path()
        ..moveTo(x0, barY + 3)
        ..quadraticBezierTo(cx - (cx - x0) * .55, barY + depth, cx, barY + depth)
        ..quadraticBezierTo(cx + (x1 - cx) * .55, barY + depth, x1, barY + 3);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..shader = _brassH.createShader(Rect.fromLTRB(x0, barY, x1, barY + depth))
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }

    arc(slotX(0), slotX(8), 44, 4.2, 1);
    arc(slotX(2), slotX(6), 24, 3, .9);

    // Bar.
    final bar = RRect.fromLTRBR(
        slotX(0) - 14, barY, slotX(8) + 14, barY + 9, const Radius.circular(4.5));
    canvas.drawRRect(bar, _fill(_brassV, bar.outerRect));

    // Shamash post.
    final post = Rect.fromLTWH(cx - 3.5, shY, 7, 46);
    canvas.drawRect(post, _fill(_brassH, post));

    for (var p = 0; p < 8; p++) {
      final x = posX(p);
      _cup(canvas, x, barY);
      if (placed.contains(p)) {
        _candle(canvas, x, barY - cupH,
            burning: lit.contains(p), seed: p, grow: ignite[p] ?? 1);
        final label = orderLabels[p];
        if (label != null && !lit.contains(p)) _label(canvas, x, label);
      }
    }
    _cup(canvas, cx, shY);
    _candle(canvas, cx, shY - cupH,
        burning: shamashLit, seed: 7, grow: ignite[-1] ?? 1);

    canvas.restore();
  }

  void _cup(Canvas canvas, double x, double y) {
    final cup = Path()
      ..moveTo(x - 13, y - cupH)
      ..quadraticBezierTo(x - 11, y - 1, x - 4, y)
      ..lineTo(x + 4, y)
      ..quadraticBezierTo(x + 11, y - 1, x + 13, y - cupH)
      ..close();
    canvas.drawPath(cup, _fill(_brassV, cup.getBounds()));
    canvas.drawRRect(
      RRect.fromLTRBR(x - 13, y - cupH - 2, x + 13, y - cupH + 1, const Radius.circular(1.5)),
      Paint()..color = AppColors.brassHi,
    );
  }

  void _candle(Canvas canvas, double x, double cupTop,
      {required bool burning, required int seed, required double grow}) {
    const len = 46.0;
    final top = cupTop - len;
    final body = Rect.fromLTWH(x - 5, top, 10, len);
    canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)), _fill(_wax, body));
    canvas.drawLine(
      Offset(x, top),
      Offset(x, top - 5),
      Paint()
        ..color = const Color(0xFF3A3028)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    if (burning && grow > 0) _flameAt(canvas, Offset(x, top - 4), (24 + seed % 3) * grow, seed);
  }

  void _flameAt(Canvas canvas, Offset base, double height, int seed) {
    final phase = t * 2 * math.pi;
    final hh = height * (1 + .05 * math.sin(phase * 1.3 + seed * 2.1) + .03 * math.sin(phase * 3.7 + seed));
    final fw = hh * .42;
    final sway = fw * (.18 * math.sin(phase * .9 + seed * 1.7) + .08 * math.sin(phase * 2.9 + seed));
    final x = base.dx, y = base.dy;

    final haloCenter = Offset(x, y - hh * .45);
    final haloR = hh * 1.6;
    canvas.drawCircle(
      haloCenter,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.flame.withValues(alpha: .55 * glow.clamp(.3, 1)),
            AppColors.flame.withValues(alpha: .12 * glow.clamp(.3, 1)),
            AppColors.flame.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(Rect.fromCircle(center: haloCenter, radius: haloR)),
    );

    final tip = Offset(x + sway, y - hh);
    final path = Path()
      ..moveTo(x, y)
      ..cubicTo(x - fw, y - hh * .28, tip.dx - fw * .35, y - hh * .62, tip.dx, tip.dy)
      ..cubicTo(tip.dx + fw * .35, y - hh * .62, x + fw, y - hh * .28, x, y)
      ..close();
    canvas.drawPath(path, _fill(_flame, path.getBounds()));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y - hh * .18), width: fw * .56, height: hh * .32),
      Paint()..color = const Color(0x8C7FA8FF),
    );
  }

  void _label(Canvas canvas, double x, int n) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: const TextStyle(
          fontFamily: AppText.sans,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Color(0xFF7A5418),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, barY - cupH - 20 - tp.height / 2));
  }

  @override
  bool shouldRepaint(MenorahPainter old) => true;
}

/// Two Shabbat candles, for the Shabbat screen.
class ShabbatCandles extends StatelessWidget {
  const ShabbatCandles({super.key, this.size = 130});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 120 / 130,
        height: size,
        child: CustomPaint(painter: _ShabbatPainter()),
      );
}

class _ShabbatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 130);
    for (final x in [40.0, 80.0]) {
      const halo = Offset(0, 34);
      canvas.drawCircle(
        Offset(x, halo.dy),
        34,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.flame.withValues(alpha: .5),
            AppColors.flame.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(x, halo.dy), radius: 34)),
      );
      final body = Rect.fromLTWH(x - 7, 52, 14, 70);
      canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)),
          Paint()..shader = MenorahPainter._wax.createShader(body));
      final flame = Path()
        ..moveTo(x, 48)
        ..cubicTo(x - 11, 40, x - 4, 28, x, 18)
        ..cubicTo(x + 4, 28, x + 11, 40, x, 48)
        ..close();
      canvas.drawPath(
          flame, Paint()..shader = MenorahPainter._flame.createShader(flame.getBounds()));
    }
  }

  @override
  bool shouldRepaint(_ShabbatPainter old) => false;
}
