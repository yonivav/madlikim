import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/core/app_phase.dart';
import 'package:madlikim/core/hanukkah.dart';
import 'package:madlikim/core/place.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  tz.TZDateTime il(int y, int m, int d, int h, [int min = 0]) =>
      tz.TZDateTime(tz.getLocation('Asia/Jerusalem'), y, m, d, h, min);

  const place = Cities.telAviv;
  late HanukkahSeason season;
  setUp(() => season = HanukkahSeason.forHebrewYear(5787, place));

  test('5787: eight nights from Friday 4.12 to Friday 11.12', () {
    expect([for (final n in season.nights) n.day],
        [4, 5, 6, 7, 8, 9, 10, 11]);
    expect(season.first.kind, NightKind.erevShabbat);
    expect(season.night(2).kind, NightKind.motzeiShabbat);
    expect(season.night(3).kind, NightKind.weekday);
    expect(season.last.kind, NightKind.erevShabbat);
  });

  test('Hebrew date labels cross into Tevet', () {
    expect(season.first.hebrewDateLabel, 'אור לכ"ה בכסלו');
    expect(season.night(6).hebrewDateLabel, "אור לל' בכסלו");
    expect(season.night(7).hebrewDateLabel, "אור לא' בטבת");
    expect(season.last.hebrewDateLabel, "אור לב' בטבת");
  });

  test('titles', () {
    expect(season.first.title, 'נר ראשון');
    expect(season.night(4).title, 'נר רביעי');
  });

  group('windows (Vision ch. 29)', () {
    test('Friday: from noon until candle lighting', () {
      final n = season.first;
      expect(n.isInWindow(il(2026, 12, 4, 11, 59)), isFalse);
      expect(n.isInWindow(il(2026, 12, 4, 12, 0)), isTrue);
      expect(n.isInWindow(n.zmanim.candleLighting), isFalse);
    });

    test('Saturday night: from end of Shabbat until 06:00', () {
      final n = season.night(2);
      expect(
          n.isInWindow(
              n.zmanim.shabbatEnd.subtract(const Duration(minutes: 1))),
          isFalse);
      expect(n.isInWindow(n.zmanim.shabbatEnd), isTrue);
      expect(n.isInWindow(il(2026, 12, 6, 5, 59)), isTrue);
      expect(n.isInWindow(il(2026, 12, 6, 6, 0)), isFalse);
    });

    test('weeknight: from sunset (default)', () {
      final n = season.night(3);
      expect(n.windowStart, n.zmanim.sunset);
      final tzeitSeason = HanukkahSeason.forHebrewYear(5787, place,
          lightingStart: LightingStart.tzeit);
      expect(tzeitSeason.night(3).windowStart, n.zmanim.tzeit);
    });

    test('nightAt finds the right night, including after midnight', () {
      expect(season.nightAt(il(2026, 12, 6, 10))!.number, 3);
      expect(season.nightAt(il(2026, 12, 6, 20))!.number, 3);
      expect(season.nightAt(il(2026, 12, 7, 1))!.number, 3);
      expect(season.nightAt(il(2026, 12, 7, 7))!.number, 4);
      expect(season.nightAt(il(2026, 12, 20, 12)), isNull);
    });
  });

  group('current season', () {
    test('in October 2026 the next season is 5787', () {
      expect(HanukkahSeason.current(il(2026, 10, 28, 12), place).hebrewYear,
          5787);
    });
    test('a few days after Hanukkah it is still the same season', () {
      expect(HanukkahSeason.current(il(2026, 12, 15, 12), place).hebrewYear,
          5787);
    });
    test('after the "after" period it moves to next year', () {
      expect(HanukkahSeason.current(il(2027, 1, 10, 12), place).hebrewYear,
          5788);
    });
    test('Hanukkah 5788 crosses into January 2028', () {
      final s = HanukkahSeason.forHebrewYear(5788, place);
      expect(s.first.month, 12);
      expect(s.last.year, 2027);
      expect(HanukkahSeason.current(il(2028, 1, 2, 12), place).hebrewYear,
          5788);
    });
  });

  group('phases (Vision ch. 26)', () {
    PhaseSnapshot at(tz.TZDateTime t, {Set<int> lit = const {}}) =>
        PhaseCalculator.compute(now: t, place: place, litNights: lit);

    test('off season, countdown, eve', () {
      expect(at(il(2026, 9, 1, 12)).phase, AppPhase.offSeason);
      expect(at(il(2026, 11, 20, 12)).phase, AppPhase.countdown);
      expect(at(il(2026, 11, 20, 12)).daysUntilStart, 14);
      expect(at(il(2026, 12, 3, 12)).phase, AppPhase.eveOfHanukkah);
    });

    test('first night is Friday: window, then Shabbat', () {
      expect(at(il(2026, 12, 4, 9)).phase, AppPhase.hanukkahDay);
      expect(at(il(2026, 12, 4, 13)).phase, AppPhase.lightingWindow);
      expect(at(il(2026, 12, 4, 13), lit: {1}).phase, AppPhase.litTonight);
      expect(at(il(2026, 12, 4, 18)).phase, AppPhase.shabbat);
      expect(at(il(2026, 12, 5, 12)).phase, AppPhase.shabbat);
    });

    test('Saturday night opens night 2', () {
      final snap = at(il(2026, 12, 5, 19));
      expect(snap.phase, AppPhase.lightingWindow);
      expect(snap.night!.number, 2);
    });

    test('weeknight', () {
      expect(at(il(2026, 12, 7, 12)).phase, AppPhase.hanukkahDay);
      expect(at(il(2026, 12, 7, 18)).phase, AppPhase.lightingWindow);
      expect(at(il(2026, 12, 7, 18), lit: {4}).phase, AppPhase.litTonight);
    });

    test('after Hanukkah', () {
      expect(at(il(2026, 12, 13, 12)).phase, AppPhase.afterHanukkah);
    });
  });
}
