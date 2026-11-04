import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'hanukkiah.dart';
import 'neri.dart';

/// "Passing the flame": the show after "הדלקתי" (Vision 14.5ב).
///
/// Tonight's new buddy arrives (an umbrella on odd nights, running in on
/// even nights), everyone gathers around the user's own candle, it catches
/// fire, hops from buddy to buddy in the real lighting order (newest first)
/// and lights each one wick to wick, then they all jump back into the
/// hanukkiah and do a stadium wave.
///
/// The timeline is a pure function ([ShowTimeline.frame]) that mirrors
/// docs/design/neri/show.js number for number, so the prototype video and
/// the app stay the same. Stage: 360 x 560, actors anchored at their feet.
class ShowTimeline {
  ShowTimeline(this.n, {this.meTipFrac = .04})
      : dt = n <= 4 ? .46 : .38 {
    passEnd = pass + n * dt;
    back = passEnd + .35;
    finale = back + .9;
    end = finale + .9;
  }

  /// Night number: how many buddies (1..8).
  final int n;

  /// Where the user's flame tip sits in their Neri, as a fraction of its
  /// height from the top (depends on the build).
  final double meTipFrac;

  static const width = 360.0;
  static const height = 560.0;
  static const mt = 300.0; // top of the hanukkiah box (360 x 200)
  static const feet = .957 * 1.5; // feet below the top of a Neri, in widths
  static const wick = (.957 - .28) * 1.5; // a buddy's wick above its feet
  static const buddyW = 42.0, circleW = 56.0, meW = 110.0, meVisitW = 80.0;
  static const arrive = 1.0, gather = 1.0, ignite = 2.3, pass = 2.65;

  final double dt;
  late final double passEnd, back, finale, end;

  /// When the panel (+N, buttons) should be shown.
  double get done => finale + .5;

  /// Lighting buddy j (0 = first) happens at this time.
  double touchAt(int j) => pass + j * dt + .6 * dt;

  static double meTipFor(NeriBuild b) => (b.t - 70) / 300;

  static double _lerp(double a, double b, double u) => a + (b - a) * u;
  static double _clamp01(double u) => u < 0 ? 0 : (u > 1 ? 1 : u);
  static double _ease(double u) => u < .5 ? 2 * u * u : 1 - math.pow(-2 * u + 2, 2).toDouble() / 2;
  static double _prog(double t, double start, double dur) => _clamp01((t - start) / dur);

  static double slotX(int i) => 180 + (i - 4) * 36.0;
  static double posX(int p) => p <= 3 ? slotX(8 - p) : slotX(7 - p);

  static Spot buddyHome(int p) => Spot(posX(p), mt + 88 + feet * buddyW, buddyW);
  static Spot meHome() => const Spot(180, mt + 52 + feet * buddyW, buddyW);
  static Spot meCenter() => const Spot(180, 300, meW);

  Spot circleSpot(int j) {
    const a0 = math.pi * .97, a1 = math.pi * 2.03;
    final a = n == 1 ? math.pi * 1.25 : _lerp(a0, a1, j / (n - 1));
    return Spot(180 + 150 * math.cos(a), 232 + 112 * math.sin(a), circleW);
  }

  Spot visitSpot(int j) {
    final c = circleSpot(j);
    final side = c.x < 180 ? -1.0 : 1.0;
    final rot = (c.x - 180).abs() < .01 ? .15 : side * .38;
    final tip = (.957 - meTipFrac) * 1.5 * meVisitW;
    final wx = c.x, wy = c.y - wick * c.w;
    return Spot(wx - tip * math.sin(rot), wy + tip * math.cos(rot) + 4, meVisitW, rot);
  }

  static Spot hop(Spot a, Spot b, double u, [double h = 40]) {
    final e = _ease(u);
    return Spot(
      _lerp(a.x, b.x, e),
      _lerp(a.y, b.y, e) - math.sin(math.pi * u) * h,
      _lerp(a.w, b.w, e),
      _lerp(a.rot, b.rot, e),
    );
  }

  ShowFrame frame(double t) {
    final actors = <ShowActor>[];
    final sparks = <ShowSpark>[];
    Umbrella? umbrella;
    final menorah = (1 - .7 * _prog(t, gather, .5) + .7 * _prog(t, back, .6)).clamp(0.0, 1.0);

    // ---- buddies ----
    for (var p = 0; p < n; p++) {
      final j = n - 1 - p; // lighting order
      final home = buddyHome(p), spot = circleSpot(j);
      final litAt = touchAt(j);
      final lit = t >= litAt;
      Spot pos;
      var mood = NeriMood.calm;
      var arms = NeriArms.down;

      if (t < gather) {
        if (p == n - 1) {
          final u = _prog(t, 0, arrive * .9);
          if (n.isOdd) {
            final e = 1 - math.pow(1 - u, 2).toDouble();
            final rot = math.sin(u * 9) * .18 * (1 - u);
            pos = Spot(home.x + math.sin(u * 9) * 16 * (1 - u), _lerp(-40, home.y, e), home.w, rot);
            if (u < 1) {
              umbrella = Umbrella(pos.x, pos.y - feet * home.w - 6, home.w * 1.5, rot,
                  1 - _prog(t, .8, .15));
            }
            arms = NeriArms.up;
          } else {
            pos = Spot(_lerp(-30, home.x, _ease(u)),
                home.y - (math.sin(u * math.pi * 5)).abs() * 12 * (1 - u * .5), home.w, .12 * (1 - u));
            arms = NeriArms.wave;
          }
          mood = u < 1 ? NeriMood.excited : NeriMood.happy;
        } else {
          pos = home;
        }
      } else if (t < back) {
        final u = _prog(t, gather + .05 * j, .7);
        pos = u < 1 ? hop(home, spot, u, 46) : spot;
        mood = NeriMood.happy;
        if (t >= ignite - .35 && t < pass) {
          arms = NeriArms.up;
          mood = NeriMood.excited;
        }
        if (lit) {
          final v = _prog(t, litAt, .35);
          pos = pos.up(math.sin(math.pi * v) * 16);
          arms = v < 1 ? NeriArms.up : NeriArms.down;
          mood = NeriMood.excited;
        }
      } else {
        final u = _prog(t, back + .04 * j, .75);
        pos = u < 1 ? hop(spot, home, u, 50) : home;
        mood = NeriMood.happy;
        if (t >= finale) {
          final v = _prog(t, finale + .07 * (n - 1 - p), .32);
          pos = pos.up(math.sin(math.pi * v) * 10);
          mood = NeriMood.excited;
          arms = v > 0 && v < 1 ? NeriArms.up : NeriArms.down;
        }
      }
      actors.add(ShowActor(p: p, spot: pos, lit: lit, mood: mood, arms: arms));
    }

    // ---- me (the shamash) ----
    {
      final home = meHome(), center = meCenter();
      var pos = home;
      var mood = NeriMood.happy;
      var arms = NeriArms.down;
      final lit = t >= ignite;
      var scale = 1.0;
      if (t < gather) {
        mood = NeriMood.wink;
      } else if (t < pass) {
        final u = _prog(t, gather + .05, .75);
        pos = u < 1 ? hop(home, center, u, 70) : center;
        if (t >= ignite - .35) {
          arms = NeriArms.up;
          mood = NeriMood.excited;
        }
        final pop = _prog(t, ignite, .4);
        if (pop > 0 && pop < 1) scale = 1 + math.sin(math.pi * pop) * .14;
      } else if (t < passEnd) {
        final j = math.min(n - 1, ((t - pass) / dt).floor());
        final from = j == 0 ? center : visitSpot(j - 1);
        pos = hop(from, visitSpot(j), _prog(t, pass + j * dt, .5 * dt), 26);
        arms = NeriArms.point;
        mood = NeriMood.excited;
      } else if (t < back) {
        pos = hop(visitSpot(n - 1), center, _prog(t, passEnd, .3), 24);
        arms = NeriArms.up;
        mood = NeriMood.excited;
      } else {
        final u = _prog(t, back + .15, .8);
        pos = u < 1 ? hop(center, home, u, 60) : home;
        mood = t >= finale ? NeriMood.wink : NeriMood.happy;
        if (t >= finale) {
          final v = _prog(t, finale + .07 * n, .32);
          pos = pos.up(math.sin(math.pi * v) * 10);
        }
      }
      actors.add(ShowActor(
        p: -1,
        spot: Spot(pos.x, pos.y, pos.w * scale, pos.rot),
        lit: lit,
        mood: mood,
        arms: arms,
        front: t > gather && t < back,
      ));
    }

    // ---- sparks: a burst when I ignite, a small one at every touch ----
    void burst(double cx, double cy, double start, int count, double dist, double size) {
      final u = _prog(t, start, .5);
      if (u <= 0 || u >= 1) return;
      for (var i = 0; i < count; i++) {
        final a = i / count * math.pi * 2 + start;
        final d = dist * (1 - math.pow(1 - u, 3).toDouble());
        sparks.add(ShowSpark(cx + math.cos(a) * d, cy + math.sin(a) * d * .9 - u * 12,
            size * (1 - u * .7), 1 - u, i.isEven));
      }
    }

    final c = meCenter();
    burst(c.x, c.y - (.957 - meTipFrac) * 1.5 * c.w + 20, ignite, 16, 90, 5);
    for (var j = 0; j < n; j++) {
      final s = circleSpot(j);
      burst(s.x, s.y - wick * s.w - 8, touchAt(j), 8, 34, 3.5);
    }

    actors.sort((a, b) => (a.spot.y + (a.front ? 1000 : 0)).compareTo(b.spot.y + (b.front ? 1000 : 0)));
    return ShowFrame(actors, sparks, menorah, umbrella);
  }
}

@immutable
class Spot {
  const Spot(this.x, this.y, this.w, [this.rot = 0]);
  final double x, y, w, rot;
  Spot up(double dy) => Spot(x, y - dy, w, rot);
}

class ShowActor {
  ShowActor({
    required this.p,
    required this.spot,
    required this.lit,
    required this.mood,
    required this.arms,
    this.front = false,
  });

  /// Buddy position 0..7, or -1 for the user's own candle.
  final int p;
  final Spot spot;
  final bool lit;
  final NeriMood mood;
  final NeriArms arms;
  final bool front;
}

class ShowSpark {
  ShowSpark(this.x, this.y, this.r, this.alpha, this.gold);
  final double x, y, r, alpha;
  final bool gold;
}

class Umbrella {
  Umbrella(this.x, this.y, this.w, this.rot, this.open);
  final double x, y, w, rot, open;
}

class ShowFrame {
  ShowFrame(this.actors, this.sparks, this.menorah, this.umbrella);
  final List<ShowActor> actors;
  final List<ShowSpark> sparks;
  final double menorah;
  final Umbrella? umbrella;
}

/// Plays the show. Tap to skip to the end. With "reduce motion" on, it
/// starts at the end. [onDone] fires once, when the panel should appear.
class LightingShow extends StatefulWidget {
  const LightingShow({
    super.key,
    required this.night,
    required this.me,
    this.onDone,
  });

  final int night;
  final NeriLook me;
  final VoidCallback? onDone;

  @override
  State<LightingShow> createState() => _LightingShowState();
}

class _LightingShowState extends State<LightingShow> with SingleTickerProviderStateMixin {
  late final ShowTimeline _tl =
      ShowTimeline(math.max(1, math.min(8, widget.night)), meTipFrac: ShowTimeline.meTipFor(widget.me.build));
  late final Ticker _ticker = createTicker(_tick);
  double _t = 0;
  double _offset = 0; // added by "skip"
  bool _doneFired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _ticker.stop();
      _jumpToEnd();
    } else if (!_ticker.isActive && _t < _tl.end) {
      _ticker.start();
    }
  }

  void _tick(Duration d) {
    final prev = _t;
    final t = d.inMicroseconds / 1e6 + _offset;
    _haptics(prev, t);
    setState(() => _t = t);
    if (t >= _tl.done) _fireDone();
    if (t >= _tl.end + .5) _ticker.stop();
  }

  void _haptics(double a, double b) {
    bool crossed(double x) => a < x && b >= x;
    if (crossed(ShowTimeline.ignite)) HapticFeedback.mediumImpact();
    for (var j = 0; j < _tl.n; j++) {
      if (crossed(_tl.touchAt(j))) HapticFeedback.selectionClick();
    }
    if (crossed(_tl.finale)) HapticFeedback.heavyImpact();
  }

  void _fireDone() {
    if (_doneFired) return;
    _doneFired = true;
    widget.onDone?.call();
  }

  void _jumpToEnd() {
    _t = _tl.end;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fireDone();
    });
  }

  void _skip() {
    if (_t >= _tl.done) return;
    if (_ticker.isActive) {
      _offset += _tl.finale - _t;
    } else {
      setState(_jumpToEnd);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _tl.frame(_t);
    final litCount = f.actors.where((a) => a.lit).length;
    final hs = 200.0 + litCount * 30;
    final haloY = f.menorah < .8 ? 200.0 : 390.0;
    return Semantics(
      label: 'הנרות נדלקים. נגיעה מדלגת לסוף',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: ShowTimeline.width,
            height: ShowTimeline.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  left: 180 - hs / 2,
                  top: haloY - hs / 2,
                  width: hs,
                  height: hs,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFC85A).withValues(alpha: .12 + litCount * .05),
                            const Color(0x00FFC85A),
                          ],
                          stops: const [0, .65],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: ShowTimeline.mt,
                  width: 360,
                  height: 200,
                  child: Opacity(
                    opacity: f.menorah,
                    child: CustomPaint(painter: HanukkiahFramePainter()),
                  ),
                ),
                for (final a in f.actors) _actor(a),
                if (f.umbrella != null) _umbrella(f.umbrella!),
                Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _SparkPainter(f.sparks))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actor(ShowActor a) {
    final s = a.spot;
    return Positioned(
      key: ValueKey(a.p),
      left: s.x - s.w / 2,
      top: s.y - ShowTimeline.feet * s.w,
      child: Transform.rotate(
        angle: s.rot,
        alignment: const Alignment(0, .914), // the feet
        child: Neri(
          look: a.p < 0 ? widget.me : null,
          color: a.p < 0 ? NeriColor.apricot : NeriColor.forNight(a.p + 1),
          size: s.w,
          mood: a.mood,
          arms: a.arms,
          lit: a.lit,
          glow: a.p < 0 ? .9 : .6,
          animate: false,
        ),
      ),
    );
  }

  Widget _umbrella(Umbrella u) => Positioned(
        left: u.x - u.w / 2,
        top: u.y - u.w * .85,
        width: u.w,
        height: u.w,
        child: Opacity(
          opacity: u.open.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: u.rot,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleY: .3 + .7 * u.open,
              alignment: Alignment.bottomCenter,
              child: CustomPaint(painter: _UmbrellaPainter()),
            ),
          ),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks);
  final List<ShowSpark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final glow = Paint()
        ..color = (s.gold ? const Color(0xFFFFB020) : const Color(0xFFFFE9A0)).withValues(alpha: s.alpha * .8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.r * 1.5);
      canvas.drawCircle(Offset(s.x, s.y), s.r * 1.6, glow);
      canvas.drawCircle(Offset(s.x, s.y), s.r,
          Paint()..color = (s.gold ? const Color(0xFFFFD45C) : Colors.white).withValues(alpha: s.alpha));
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}

/// A little striped umbrella (design box 60 x 60), same as the prototype.
class _UmbrellaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60, size.height / 60);
    canvas.drawLine(
        const Offset(30, 50),
        const Offset(30, 22),
        Paint()
          ..color = const Color(0xFF1E2340)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    final canopy = Path()
      ..moveTo(4, 26)
      ..quadraticBezierTo(30, -6, 56, 26)
      ..quadraticBezierTo(49, 21, 43, 26)
      ..quadraticBezierTo(36, 20, 30, 26)
      ..quadraticBezierTo(24, 20, 17, 26)
      ..quadraticBezierTo(11, 21, 4, 26)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFFFF8FAE));
    canvas.drawPath(
        Path()
          ..moveTo(17, 26)
          ..quadraticBezierTo(22, 6, 30, 4)
          ..quadraticBezierTo(26, 14, 30, 26)
          ..close(),
        Paint()..color = const Color(0xFFFFC63A));
    canvas.drawPath(
        Path()
          ..moveTo(43, 26)
          ..quadraticBezierTo(38, 6, 30, 4)
          ..quadraticBezierTo(34, 14, 30, 26)
          ..close(),
        Paint()..color = const Color(0xFF7FB0FF));
    canvas.drawPath(
        Path()
          ..moveTo(12, 16)
          ..quadraticBezierTo(20, 8, 28, 7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xB3FFFFFF));
  }

  @override
  bool shouldRepaint(_UmbrellaPainter old) => false;
}
