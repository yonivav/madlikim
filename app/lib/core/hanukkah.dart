import 'package:timezone/timezone.dart' as tz;

import 'hebrew_calendar.dart';
import 'hebrew_numerals.dart';
import 'place.dart';
import 'zmanim.dart';

enum NightKind { weekday, erevShabbat, motzeiShabbat }

/// When the user prefers to light on weeknights.
enum LightingStart { sunset, tzeit }

/// One night of Hanukkah at one place.
class HanukkahNight {
  HanukkahNight({
    required this.number,
    required this.hebrewYear,
    required this.year,
    required this.month,
    required this.day,
    required this.zmanim,
    required this.hebrewDay,
    required this.hebrewMonth,
    required this.lightingStart,
  });

  /// 1..8
  final int number;
  final int hebrewYear;

  /// Civil date of the evening we light on.
  final int year;
  final int month;
  final int day;

  final DayZmanim zmanim;

  /// Hebrew date that begins this evening ("אור ל...").
  final int hebrewDay;
  final int hebrewMonth;

  final LightingStart lightingStart;

  int get weekday => DateTime.utc(year, month, day).weekday;

  NightKind get kind => switch (weekday) {
        DateTime.friday => NightKind.erevShabbat,
        DateTime.saturday => NightKind.motzeiShabbat,
        _ => NightKind.weekday,
      };

  bool get isFirst => number == 1;
  bool get isLast => number == 8;

  /// "אור לכ"ה בכסלו"
  String get hebrewDateLabel =>
      'אור ל${hebrewNumeral(hebrewDay)} ב${hebrewMonthName(hebrewMonth)}';

  /// "נר רביעי"
  String get title => 'נר ${ordinalsMasculine[number]}';

  /// Earliest moment the app accepts "הדלקתי" for this night.
  DateTime get windowStart => switch (kind) {
        NightKind.erevShabbat => zmanim.atLocal(12),
        NightKind.motzeiShabbat => zmanim.shabbatEnd,
        NightKind.weekday => lightingStart == LightingStart.tzeit
            ? zmanim.tzeit
            : zmanim.sunset,
      };

  /// The ideal "light by" time we show the user.
  DateTime get preferredUntil => switch (kind) {
        NightKind.erevShabbat => zmanim.candleLighting,
        NightKind.motzeiShabbat =>
          zmanim.shabbatEnd.add(const Duration(minutes: 30)),
        NightKind.weekday => zmanim.tzeit.add(const Duration(minutes: 30)),
      };

  /// After this the night is "past" (06:00 next morning, or Shabbat start).
  DateTime get windowEnd {
    if (kind == NightKind.erevShabbat) return zmanim.candleLighting;
    final next = DateTime.utc(year, month, day).add(const Duration(days: 1));
    return tz.TZDateTime(tz.getLocation(zmanim.place.timeZone), next.year,
            next.month, next.day, 6)
        .toUtc();
  }

  bool isInWindow(DateTime now) =>
      !now.isBefore(windowStart) && now.isBefore(windowEnd);

  bool hasStarted(DateTime now) => !now.isBefore(windowStart);

  /// Start of this civil day, at the place, as UTC.
  DateTime get dayStart => zmanim.atLocal(0);
}

/// All eight nights of one Hanukkah at one place.
class HanukkahSeason {
  HanukkahSeason._(this.hebrewYear, this.nights);

  factory HanukkahSeason.forHebrewYear(int hebrewYear, Place place,
      {LightingStart lightingStart = LightingStart.sunset}) {
    // 25 Kislev begins the evening before its civil date.
    final kislev25 =
        HebrewCalendar.fixedFromHebrew(hebrewYear, HebrewMonth.kislev, 25);
    final kislevLength =
        HebrewCalendar.daysInMonth(HebrewMonth.kislev, hebrewYear);
    final nights = <HanukkahNight>[];
    for (var n = 1; n <= 8; n++) {
      final eve = HebrewCalendar.dateFromFixed(kislev25 + n - 2);
      var hDay = 24 + n;
      var hMonth = HebrewMonth.kislev;
      if (hDay > kislevLength) {
        hDay -= kislevLength;
        hMonth = HebrewMonth.tevet;
      }
      nights.add(HanukkahNight(
        number: n,
        hebrewYear: hebrewYear,
        year: eve.year,
        month: eve.month,
        day: eve.day,
        zmanim: DayZmanim.compute(place, eve.year, eve.month, eve.day),
        hebrewDay: hDay,
        hebrewMonth: hMonth,
        lightingStart: lightingStart,
      ));
    }
    return HanukkahSeason._(hebrewYear, nights);
  }

  /// The season that is current at [now]: the one in progress, the one that
  /// just ended (within [afterDays]), or the next one.
  factory HanukkahSeason.current(DateTime now, Place place,
      {LightingStart lightingStart = LightingStart.sunset,
      int afterDays = 7}) {
    final local = tz.TZDateTime.from(now, tz.getLocation(place.timeZone));
    for (final gYear in [local.year - 1, local.year, local.year + 1]) {
      final season = HanukkahSeason.forHebrewYear(
          HebrewCalendar.hebrewYearForHanukkahIn(gYear), place,
          lightingStart: lightingStart);
      if (now.isBefore(season.afterPeriodEnd(afterDays))) return season;
    }
    // Unreachable in practice.
    return HanukkahSeason.forHebrewYear(
        HebrewCalendar.hebrewYearForHanukkahIn(local.year + 1), place,
        lightingStart: lightingStart);
  }

  final int hebrewYear;
  final List<HanukkahNight> nights;

  HanukkahNight night(int n) => nights[n - 1];
  HanukkahNight get first => nights.first;
  HanukkahNight get last => nights.last;

  /// Start of the civil day before the first night.
  DateTime get eveDayStart =>
      first.dayStart.subtract(const Duration(days: 1));

  /// When the last night's window closes (the morning of the 8th day).
  DateTime get end => last.windowEnd;

  DateTime afterPeriodEnd(int days) => end.add(Duration(days: days));

  /// The night whose civil evening is "today" at [now], or whose window is
  /// still open (after midnight). Null outside the eight nights.
  HanukkahNight? nightAt(DateTime now) {
    for (final n in nights.reversed) {
      if (n.isInWindow(now)) return n;
    }
    for (final n in nights) {
      final nextDay = n.dayStart.add(const Duration(days: 1));
      if (!now.isBefore(n.dayStart) && now.isBefore(nextDay)) return n;
    }
    return null;
  }

  /// Sum of 1..8.
  static const maxLight = 36;
}
