import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/core/place.dart';
import 'package:madlikim/core/sun_calculator.dart';
import 'package:madlikim/core/zmanim.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  tz.TZDateTime il(int y, int m, int d, int h, int min) =>
      tz.TZDateTime(tz.getLocation('Asia/Jerusalem'), y, m, d, h, min);

  void near(DateTime actual, DateTime expected, {int minutes = 2}) {
    expect(actual.difference(expected).inMinutes.abs(),
        lessThanOrEqualTo: minutes,
        reason: 'got ${actual.toUtc()} expected ${expected.toUtc()}');
  }

  test('Tel Aviv sunset, winter and summer', () {
    final dec = SunCalculator.sunTime(
        year: 2026, month: 12, day: 4,
        lat: 32.0853, lng: 34.7818,
        depression: SunCalculator.sunsetDepression)!;
    near(dec, il(2026, 12, 4, 16, 37));

    final jun = SunCalculator.sunTime(
        year: 2026, month: 6, day: 21,
        lat: 32.0853, lng: 34.7818,
        depression: SunCalculator.sunsetDepression)!;
    near(jun, il(2026, 6, 21, 19, 50));
  });

  test('candle lighting offsets by city', () {
    final ta = DayZmanim.compute(Cities.telAviv, 2026, 12, 4);
    expect(ta.sunset.difference(ta.candleLighting).inMinutes, 20);
    final jlm = DayZmanim.compute(Cities.jerusalem, 2026, 12, 4);
    expect(jlm.sunset.difference(jlm.candleLighting).inMinutes, 40);
  });

  test('tzeit is 30 to 45 minutes after sunset in Israel', () {
    final z = DayZmanim.compute(Cities.telAviv, 2026, 12, 5);
    final gap = z.tzeit.difference(z.sunset).inMinutes;
    expect(gap, inInclusiveRange(30, 45));
  });

  group('isShabbat', () {
    const place = Cities.telAviv;
    test('Friday afternoon before candles: no', () {
      expect(ShabbatClock.isShabbat(il(2026, 12, 4, 15, 30), place), isFalse);
    });
    test('Friday evening after candles: yes', () {
      expect(ShabbatClock.isShabbat(il(2026, 12, 4, 17, 0), place), isTrue);
    });
    test('Saturday noon: yes', () {
      expect(ShabbatClock.isShabbat(il(2026, 12, 5, 12, 0), place), isTrue);
    });
    test('Saturday night after tzeit: no', () {
      expect(ShabbatClock.isShabbat(il(2026, 12, 5, 18, 0), place), isFalse);
    });
    test('Thursday: no', () {
      expect(ShabbatClock.isShabbat(il(2026, 12, 3, 20, 0), place), isFalse);
    });
    test('end of Shabbat is Saturday tzeit', () {
      final end = ShabbatClock.endOfShabbat(il(2026, 12, 4, 20, 0), place)!;
      final z = DayZmanim.compute(place, 2026, 12, 5);
      expect(end, z.shabbatEnd);
    });
  });
}
