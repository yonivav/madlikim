import 'package:flutter/material.dart';

import '../theme.dart';
import 'neri.dart';

/// A line-drawn hanukkiah with candle buddies standing in the cups.
///
/// Positions 0..7 count from the RIGHT (night 1's candle). The candle in
/// position p is night p+1's buddy color. The shamash is Neri himself.
/// Design box 360 x 200 (same as the prototype).
class Hanukkiah extends StatelessWidget {
  const Hanukkiah({
    super.key,
    required this.placed,
    this.lit = const {},
    this.shamashLit = true,
    this.showOrder = false,
    this.width = 360,
    this.shamashLook = const NeriLook(NeriColor.apricot, pattern: NeriPattern.none),
  });

  /// The shamash is the user's own character.
  final NeriLook shamashLook;

  /// How many candles stand in the cups (tonight's night number).
  final int placed;
  final Set<int> lit;
  final bool shamashLit;

  /// Numbers above the candles: the order to light them.
  final bool showOrder;
  final double width;

  static double slotX(int i) => 180 + (i - 4) * 36.0;
  static double posX(int p) => p <= 3 ? slotX(8 - p) : slotX(7 - p);

  /// Lighting order for [night] candles: the newest (leftmost) first.
  static Map<int, int> lightingOrder(int night) =>
      {for (var i = 0; i < night; i++) night - 1 - i: i + 1};

  @override
  Widget build(BuildContext context) {
    final s = width / 360;
    final order = lightingOrder(placed);
    return Semantics(
      label: lit.isEmpty
          ? 'חנוכייה עם $placed נרות מוכנים. מדליקים משמאל לימין'
          : 'חנוכייה עם ${lit.length} נרות דולקים',
      child: SizedBox(
        width: width,
        height: 200 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _FramePainter())),
            Positioned(
              left: (180 - 21) * s,
              top: 52 * s,
              child: Neri(
                look: shamashLook,
                size: 42 * s,
                mood: NeriMood.wink,
                lit: shamashLit,
                glow: .6,
                animate: false,
              ),
            ),
            for (var p = 0; p < placed && p < 8; p++) ...[
              Positioned(
                left: (posX(p) - 21) * s,
                top: 88 * s,
                child: Neri(
                  size: 42 * s,
                  color: NeriColor.forNight(p + 1),
                  mood: lit.contains(p) ? NeriMood.happy : NeriMood.calm,
                  lit: lit.contains(p),
                  glow: .5,
                  animate: false,
                ),
              ),
              if (showOrder && !lit.contains(p))
                Positioned(
                  left: (posX(p) - 11) * s,
                  top: 56 * s,
                  child: Container(
                    width: 22 * s,
                    height: 22 * s,
                    alignment: Alignment.center,
                    decoration: Gloss.candy(shape: BoxShape.circle),
                    child: Text('${order[p]}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontFamily: AppText.round,
                            fontWeight: FontWeight.w600,
                            fontSize: 12 * s,
                            height: 1,
                            color: Colors.white)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A brass hanukkiah: soft gold strokes with round ends, oval cups with a
/// little shine. No ink outlines, so it sits in the glossy style.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 360, size.height / 200);
    canvas.translate(0, 30);
    const brass = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE08A), Color(0xFFE2A43A), Color(0xFFC9852A)],
    );
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = brass.createShader(const Rect.fromLTWH(0, 80, 360, 95));
    // soft shadow under the whole thing
    canvas.drawOval(
      const Rect.fromLTWH(120, 162, 120, 14),
      Paint()
        ..color = const Color(0x33B06A10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 130)
        ..quadraticBezierTo(100, 165, 180, 165)
        ..quadraticBezierTo(260, 165, 330, 130),
      metal..strokeWidth = 5,
    );
    canvas.drawLine(const Offset(20, 128), const Offset(340, 128), metal..strokeWidth = 9);
    canvas.drawLine(const Offset(180, 128), const Offset(180, 164), metal..strokeWidth = 7);
    canvas.drawLine(const Offset(180, 128), const Offset(180, 92), metal..strokeWidth = 6);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(180, 167), width: 64, height: 12),
        Paint()..shader = brass.createShader(const Rect.fromLTWH(148, 161, 64, 12)));
    // a highlight along the bar
    canvas.drawLine(
        const Offset(28, 125.5),
        const Offset(332, 125.5),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2
          ..color = const Color(0x99FFFFFF));

    void drawCup(double x, double y) {
      final r = Rect.fromCenter(center: Offset(x, y + 5), width: 28, height: 14);
      canvas.drawOval(r, Paint()..shader = brass.createShader(r));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y + 2.5), width: 15, height: 4),
          Paint()..color = const Color(0x99FFFFFF));
    }

    for (var p = 0; p < 8; p++) {
      drawCup(Hanukkiah.posX(p), 118);
    }
    drawCup(180, 82);
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
