import 'package:timezone/timezone.dart' as tz;

import 'place.dart';
import 'sun_calculator.dart';

/// Halachic times for one civil date at one place. All values are UTC
/// instants; convert with [local] for display.
class DayZmanim {
  DayZmanim._(this.place, this.year, this.month, this.day, this.sunset,
      this.tzeit);

  factory DayZmanim.compute(Place place, int year, int month, int day) {
    final sunset = SunCalculator.sunTime(
      year: year,
      month: month,
      day: day,
      lat: place.lat,
      lng: place.lng,
      depression: SunCalculator.sunsetDepression,
    );
    final tzeit = SunCalculator.sunTime(
      year: year,
      month: month,
      day: day,
      lat: place.lat,
      lng: place.lng,
      depression: SunCalculator.tzeitDepression,
    );
    // Fallbacks only matter near the poles; keep the app usable anyway.
    final fallbackSunset = tz.TZDateTime(
            tz.getLocation(place.timeZone), year, month, day, 17)
        .toUtc();
    final s = sunset ?? fallbackSunset;
    return DayZmanim._(place, year, month, day, s,
        tzeit ?? s.add(const Duration(minutes: 40)));
  }

  final Place place;
  final int year;
  final int month;
  final int day;
  final DateTime sunset;
  final DateTime tzeit;

  /// Shabbat candle lighting (meaningful on Fridays).
  DateTime get candleLighting =>
      sunset.subtract(Duration(minutes: place.candleLightingOffsetMinutes));

  /// End of Shabbat (meaningful on Saturdays).
  DateTime get shabbatEnd => tzeit;

  tz.TZDateTime local(DateTime utc) =>
      tz.TZDateTime.from(utc, tz.getLocation(place.timeZone));

  /// A wall-clock time on this date, at this place, as UTC.
  DateTime atLocal(int hour, [int minute = 0]) => tz.TZDateTime(
          tz.getLocation(place.timeZone), year, month, day, hour, minute)
      .toUtc();
}

/// Shabbat helpers.
class ShabbatClock {
  /// True from Friday candle lighting until Saturday tzeit, at [place].
  static bool isShabbat(DateTime moment, Place place) {
    final loc = tz.getLocation(place.timeZone);
    final local = tz.TZDateTime.from(moment, loc);
    if (local.weekday == DateTime.friday) {
      final z = DayZmanim.compute(place, local.year, local.month, local.day);
      return !moment.isBefore(z.candleLighting);
    }
    if (local.weekday == DateTime.saturday) {
      final z = DayZmanim.compute(place, local.year, local.month, local.day);
      return moment.isBefore(z.shabbatEnd);
    }
    return false;
  }

  /// When the Shabbat containing [moment] ends (null if not Shabbat).
  static DateTime? endOfShabbat(DateTime moment, Place place) {
    if (!isShabbat(moment, place)) return null;
    final loc = tz.getLocation(place.timeZone);
    final local = tz.TZDateTime.from(moment, loc);
    final saturday = local.weekday == DateTime.saturday
        ? local
        : local.add(const Duration(days: 1));
    return DayZmanim.compute(
            place, saturday.year, saturday.month, saturday.day)
        .shabbatEnd;
  }
}
