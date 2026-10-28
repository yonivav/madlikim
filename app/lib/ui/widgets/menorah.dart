import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A drawn hanukkiah with eight candle positions and a shamash.
///
/// Positions are numbered 0..7 from the RIGHT (that is where night 1's
/// candle goes). The shamash sits in the middle, raised.
class Menorah extends StatefulWidget {
  const Menorah({
    super.key,
    this.placed = const {},
    this.lit = const {},
    this.shamashLit = false,
    this.orderLabels = const {},
    this.height = 200,
  });

  /// Positions that hold a candle.
  final Set<int> placed;

  /// Positions whose candle is burning.
  final Set<int> lit;

  final bool shamashLit;

  /// Small numbers drawn above positions (lighting order).
  final Map<int, int> orderLabels;

  final double height;

  /// Lighting order for [night] candles: newest (leftmost) first.
  static Map<int, int> lightingOrder(int night) =>
      {for (var i = 0; i < night; i++) night - 1 - i: i + 1};

  @override
  State<Menorah> createState() => _MenorahState();
}

class _MenorahState extends State<Menorah> with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.placed.length + (widget.shamashLit ? 1 : 0);
    return Semantics(
      label: 'חנוכייה עם ${widget.lit.length} נרות דולקים',
      value: '$count',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _flicker,
            builder: (context, _) => CustomPaint(
              painter: _MenorahPainter(
                placed: widget.placed,
                lit: widget.lit,
                shamashLit: widget.shamashLit,
                orderLabels: widget.orderLabels,
                t: _flicker.value,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenorahPainter extends CustomPainter {
  _MenorahPainter({
    required this.placed,
    required this.lit,
    required this.shamashLit,
    required this.orderLabels,
    required this.t,
    required this.textDirection,
  });

  final Set<int> placed;
  final Set<int> lit;
  final bool shamashLit;
  final Map<int, int> orderLabels;
  final double t;
  final TextDirection textDirection;

  /// Slot index from the LEFT (0..8, 4 = shamash) for position p.
  static int slotFor(int p) => p <= 3 ? 8 - p : 7 - p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final usable = math.min(w, h * 2.2);
    final left = (w - usable) / 2;
    final slotW = usable / 9;
    final cupY = h * 0.52;
    final baseY = h * 0.95;

    final metal = Paint()
      ..color = AppColors.silver
      ..style = PaintingStyle.fill;
    final metalStroke = Paint()
      ..color = AppColors.silver
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, slotW * 0.08)
      ..strokeCap = StrokeCap.round;

    final centerX = left + slotW * 4.5;

    // Base and stem.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, baseY - h * 0.03),
            width: usable * 0.32,
            height: h * 0.05),
        const Radius.circular(6),
      ),
      metal,
    );
    canvas.drawLine(Offset(centerX, baseY - h * 0.05),
        Offset(centerX, cupY - h * 0.12), metalStroke);

    // Arms: a gentle bowl shape joining each pair of slots.
    // Arms: nested U-shaped arcs from each cup down to the stem, the outer
    // ones deeper, like a classic hanukkiah.
    for (var s = 0; s < 9; s++) {
      if (s == 4) continue;
      final x = left + slotW * (s + 0.5);
      final reach = (s - 4).abs() / 4; // 0.25 .. 1.0
      final bottomY = cupY + h * (0.04 + 0.22 * reach);
      final path = Path()
        ..moveTo(x, cupY)
        ..quadraticBezierTo(x, bottomY, centerX, bottomY);
      canvas.drawPath(path, metalStroke);
    }

    void drawCup(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, y), width: slotW * 0.62, height: h * 0.04),
          const Radius.circular(4),
        ),
        metal,
      );
    }

    void drawCandle(double x, double topY, {required bool burning, int seed = 0}) {
      final candleH = h * 0.2;
      final candleW = slotW * 0.32;
      final body = Rect.fromLTWH(x - candleW / 2, topY, candleW, candleH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFBF2), Color(0xFFE8DCC6)],
          ).createShader(body),
      );
      // Wick.
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, topY - h * 0.02),
        Paint()
          ..color = const Color(0xFF3A3028)
          ..strokeWidth = 1.5,
      );
      if (burning) _drawFlame(canvas, Offset(x, topY - h * 0.02), h, seed);
    }

    // Shamash (raised).
    final shamashCupY = cupY - h * 0.12;
    drawCup(centerX, shamashCupY);
    drawCandle(centerX, shamashCupY - h * 0.22,
        burning: shamashLit, seed: 99);

    for (var p = 0; p < 8; p++) {
      final s = slotFor(p);
      final x = left + slotW * (s + 0.5);
      drawCup(x, cupY);
      if (placed.contains(p)) {
        drawCandle(x, cupY - h * 0.22, burning: lit.contains(p), seed: p);
      }
      final label = orderLabels[p];
      if (label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$label',
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: math.max(11, slotW * 0.32),
              fontWeight: FontWeight.w800,
              color: AppColors.nightDeep,
            ),
          ),
          textDirection: textDirection,
        )..layout();
        final center = Offset(x, cupY + h * 0.11);
        canvas.drawCircle(
            center, tp.width / 2 + 6, Paint()..color = AppColors.gold);
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _drawFlame(Canvas canvas, Offset base, double h, int seed) {
    final phase = t * 2 * math.pi;
    final wobble = math.sin(phase * 3 + seed * 1.7) * 0.08 +
        math.sin(phase * 7 + seed) * 0.04;
    final flameH = h * (0.11 + 0.012 * math.sin(phase * 5 + seed * 2.3));
    final flameW = flameH * 0.42;
    final tip = base + Offset(flameW * wobble * 2, -flameH);

    // Glow.
    canvas.drawCircle(
      base + Offset(0, -flameH * 0.45),
      flameH * 1.3,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.gold.withValues(alpha: 0.35),
          AppColors.gold.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(
            center: base + Offset(0, -flameH * 0.45), radius: flameH * 1.3)),
    );

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - flameW, base.dy - flameH * 0.25, tip.dx - flameW * 0.3,
          tip.dy + flameH * 0.35, tip.dx, tip.dy)
      ..cubicTo(tip.dx + flameW * 0.3, tip.dy + flameH * 0.35,
          base.dx + flameW, base.dy - flameH * 0.25, base.dx, base.dy)
      ..close();
    final rect = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFFFF3C4), AppColors.gold, AppColors.flame],
          stops: [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_MenorahPainter old) =>
      old.t != t ||
      old.placed != placed ||
      old.lit != lit ||
      old.shamashLit != shamashLit ||
      old.orderLabels != orderLabels;
}
