import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/ui/widgets/lighting_show.dart';
import 'package:madlikim/ui/widgets/neri.dart';

void main() {
  group('passing the flame', () {
    for (final n in [1, 2, 4, 5, 8]) {
      test('night $n: starts dark, ends lit and back in the hanukkiah', () {
        final tl = ShowTimeline(n);
        final start = tl.frame(0);
        expect(start.actors.where((a) => a.lit), isEmpty);
        expect(start.actors.length, n + 1);

        final end = tl.frame(tl.end);
        expect(end.actors.every((a) => a.lit), isTrue);
        for (final a in end.actors) {
          final home = a.p < 0 ? ShowTimeline.meHome() : ShowTimeline.buddyHome(a.p);
          expect(a.spot.x, closeTo(home.x, .01));
          expect(a.spot.y, closeTo(home.y, .01));
          expect(a.spot.w, closeTo(home.w, .01));
        }
        expect(end.menorah, closeTo(1, .01));
        expect(end.sparks, isEmpty);
      });
    }

    test('the shamash is lit before anyone else', () {
      final tl = ShowTimeline(3);
      final f = tl.frame(ShowTimeline.ignite + .01);
      expect(f.actors.firstWhere((a) => a.p < 0).lit, isTrue);
      expect(f.actors.where((a) => a.p >= 0 && a.lit), isEmpty);
    });

    test('newest candle (leftmost) is lit first, like the halacha', () {
      final tl = ShowTimeline(4);
      final f = tl.frame(tl.touchAt(0) + .01);
      final lit = f.actors.where((a) => a.p >= 0 && a.lit).map((a) => a.p).toList();
      expect(lit, [3]);
    });

    test('flame tip meets the wick when visiting', () {
      for (final n in [1, 3, 8]) {
        final tl = ShowTimeline(n, meTipFrac: ShowTimeline.meTipFor(NeriBuild.classic));
        for (var j = 0; j < n; j++) {
          final v = tl.visitSpot(j);
          final c = tl.circleSpot(j);
          final tip = (.957 - tl.meTipFrac) * 1.5 * v.w;
          final tipX = v.x + tip * math.sin(v.rot);
          final tipY = v.y - tip * math.cos(v.rot);
          expect(tipX, closeTo(c.x, .5));
          expect(tipY, closeTo(c.y - ShowTimeline.wick * c.w + 4, .5));
        }
      }
    });

    test('odd nights float in on an umbrella, even nights run in', () {
      expect(ShowTimeline(3).frame(.3).umbrella, isNotNull);
      expect(ShowTimeline(4).frame(.3).umbrella, isNull);
    });
  });
}
