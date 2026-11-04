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
  });

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
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
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

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 360, size.height / 200);
    canvas.translate(0, 30);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.ink;
    canvas.drawLine(const Offset(20, 128), const Offset(340, 128), ink..strokeWidth = 7);
    canvas.drawPath(
      Path()
        ..moveTo(30, 130)
        ..quadraticBezierTo(100, 165, 180, 165)
        ..quadraticBezierTo(260, 165, 330, 130),
      ink..strokeWidth = 4,
    );
    canvas.drawLine(const Offset(180, 128), const Offset(180, 166), ink..strokeWidth = 6);
    canvas.drawLine(const Offset(150, 168), const Offset(210, 168), ink..strokeWidth = 6);
    canvas.drawLine(const Offset(180, 128), const Offset(180, 92), ink..strokeWidth = 5);
    final cup = Paint()..color = const Color(0xFFD9A441);
    final cupLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.ink;
    void drawCup(double x, double y) {
      final r = RRect.fromLTRBR(x - 12, y, x + 12, y + 10, const Radius.circular(3));
      canvas.drawRRect(r, cup);
      canvas.drawRRect(r, cupLine);
    }

    for (var p = 0; p < 8; p++) {
      drawCup(Hanukkiah.posX(p), 118);
    }
    drawCup(180, 82);
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
