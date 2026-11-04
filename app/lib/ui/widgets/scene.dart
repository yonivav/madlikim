import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Golden light that rises behind Neri as nights are lit (the "water level"
/// of this app). [fraction] is 0..1 of the available height.
class LightLevel extends StatefulWidget {
  const LightLevel({super.key, required this.fraction});
  final double fraction;

  @override
  State<LightLevel> createState() => _LightLevelState();
}

class _LightLevelState extends State<LightLevel> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6));
  double _t = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.fraction.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, f, __) => CustomPaint(painter: _LightPainter(f, _t)),
    );
  }
}

class _LightPainter extends CustomPainter {
  _LightPainter(this.fraction, this.t);
  final double fraction;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    final top = size.height * (1 - fraction);
    Path wave(double amp, double phase, double offset) {
      final p = Path()..moveTo(0, top + offset);
      for (var x = 0.0; x <= size.width; x += 6) {
        p.lineTo(x, top + offset + math.sin(x / size.width * 2 * math.pi * 1.5 + t * 1.2 + phase) * amp);
      }
      return p;
    }

    final fill = wave(6, 0, 10)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.goldSoft, Color(0xFFFFC94F)],
        ).createShader(Rect.fromLTRB(0, top, size.width, size.height))
        ..color = Colors.white.withValues(alpha: .85),
    );
    canvas.drawPath(
      wave(5, 1.4, 18),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .7),
    );
    // A few sparkles floating in the light.
    final r = math.Random(3);
    for (var i = 0; i < 7; i++) {
      final x = r.nextDouble() * size.width;
      final y0 = top + 30 + r.nextDouble() * (size.height - top - 40);
      final y = y0 - ((t * 8 + i * 13) % 30);
      if (y < top + 14) continue;
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white.withValues(alpha: .85));
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = Colors.white.withValues(alpha: .25));
    }
  }

  @override
  bool shouldRepaint(_LightPainter old) => old.fraction != fraction || old.t != t;
}

/// An olive branch, line-drawn (the oil of the miracle).
class OliveBranch extends StatelessWidget {
  const OliveBranch({super.key, this.flip = false, this.size = 120});
  final bool flip;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.flip(
        flipX: flip,
        child: SizedBox(
          width: size,
          height: size * 110 / 120,
          child: const CustomPaint(painter: _OlivePainter()),
        ),
      );
}

class _OlivePainter extends CustomPainter {
  const _OlivePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 110);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5E6B3A);
    canvas.drawPath(
        Path()
          ..moveTo(10, 108)
          ..quadraticBezierTo(40, 70, 96, 20),
        stroke);
    final leaf = Paint()..color = const Color(0x8C9DAA6A);
    for (final (x, y, deg) in [
      (30.0, 82.0, -40.0), (44.0, 66.0, 30.0), (58.0, 54.0, -35.0),
      (70.0, 42.0, 28.0), (84.0, 30.0, -30.0), (96.0, 20.0, 10.0),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(deg * math.pi / 180);
      final r = Rect.fromCenter(center: Offset.zero, width: 26, height: 10);
      canvas.drawOval(r, leaf);
      canvas.drawOval(r, stroke);
      canvas.restore();
    }
    final olive = Paint()..color = const Color(0xFF3E4A2A);
    canvas.drawCircle(const Offset(52, 76), 5, olive);
    canvas.drawCircle(const Offset(78, 52), 5, olive);
  }

  @override
  bool shouldRepaint(_OlivePainter old) => false;
}

/// Deep blue night with stars, for the celebration and Shabbat screens.
class NightBackdrop extends StatelessWidget {
  const NightBackdrop({super.key, required this.child, this.shabbat = false});
  final Widget child;
  final bool shabbat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.35),
          radius: 1.0,
          colors: shabbat
              ? const [Color(0xFF3A3263), Color(0xFF1A1D4A), Color(0xFF0F1233)]
              : const [AppColors.nightHi, AppColors.night, AppColors.nightDeep],
          stops: const [0, .6, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [const CustomPaint(painter: _StarsPainter()), child],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(5);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * .75),
        r.nextDouble() < .2 ? 1.8 : 1.1,
        Paint()..color = Colors.white.withValues(alpha: .2 + r.nextDouble() * .5),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

/// Confetti that falls once (the celebration's one big moment).
class ConfettiFall extends StatefulWidget {
  const ConfettiFall({super.key});

  @override
  State<ConfettiFall> createState() => _ConfettiFallState();
}

class _ConfettiFallState extends State<ConfettiFall> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!still && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static const _colors = [
    AppColors.gold, Color(0xFFFF8FAE), Color(0xFF7FB0FF), Color(0xFF86E3C2), AppColors.orangeHi,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final r = math.Random(9);
    for (var i = 0; i < 40; i++) {
      final x0 = r.nextDouble() * size.width;
      final delay = r.nextDouble() * .35;
      final speed = .7 + r.nextDouble() * .6;
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0) * speed;
      if (p <= 0) continue;
      final y = -20 + p * size.height * .9;
      final x = x0 + math.sin(p * 8 + i) * 18;
      final fade = p > .8 ? (1 - p) / .2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * 9 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, -7, 9, 14), const Radius.circular(2)),
        Paint()..color = _colors[i % _colors.length].withValues(alpha: fade.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
