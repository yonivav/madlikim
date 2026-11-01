import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The home screen's hero: an arched window at night, a sill, and whatever
/// stands on it (usually the hanukkiah). Seen from the street, like the
/// lights are meant to be.
class WindowScene extends StatelessWidget {
  const WindowScene({
    super.key,
    required this.child,
    this.height = 410,
    this.overlay,
  });

  /// Stands on the sill.
  final Widget child;
  final double height;

  /// Drawn on top (greeting, settings button).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 1),
                radius: 1.2,
                colors: [Color(0xFF1D2C4F), AppColors.skyDeep],
                stops: [0, .7],
              ),
            ),
          ),
          const CustomPaint(painter: _StarsPainter()),
          Positioned(
            left: 38,
            right: 38,
            top: top + 62,
            bottom: 54,
            child: const CustomPaint(painter: _ArchPainter()),
          ),
          Positioned(left: 0, right: 0, bottom: 52, height: 230, child: child),
          Positioned(
            left: 22,
            right: 22,
            bottom: 40,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF34476F), Color(0xFF22314F)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
                ],
              ),
            ),
          ),
          if (overlay != null)
            Positioned(left: 0, right: 0, top: top, child: overlay!),
        ],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 46; i++) {
      final o = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * .72);
      paint.color = Colors.white.withValues(alpha: .12 + r.nextDouble() * .5);
      canvas.drawCircle(o, r.nextDouble() < .15 ? 1.4 : .9, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

/// Arched window frame with a center mullion and faint glass.
class _ArchPainter extends CustomPainter {
  const _ArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, size.height);
    final glass = Path.from(path)..close();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5924365C), Color(0x0D24365C)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.brass.withValues(alpha: .28),
    );
    canvas.drawLine(
      Offset(r, 0),
      Offset(r, size.height),
      Paint()
        ..strokeWidth = 1.5
        ..color = AppColors.brass.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(_ArchPainter old) => false;
}
