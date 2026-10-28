import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/core/hebrew_calendar.dart';

void main() {
  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('Rosh Hashana dates', () {
    expect(ymd(HebrewCalendar.dateFromFixed(HebrewCalendar.newYear(5786))),
        '2025-09-23');
    expect(ymd(HebrewCalendar.dateFromFixed(HebrewCalendar.newYear(5787))),
        '2026-09-12');
    expect(HebrewCalendar.dateFromFixed(HebrewCalendar.newYear(5787)).weekday,
        DateTime.saturday);
  });

  test('25 Kislev (first candle is the evening before)', () {
    // Known first-candle evenings.
    const firstCandle = {
      2024: '2024-12-25',
      2025: '2025-12-14',
      2026: '2026-12-04',
      2027: '2027-12-24',
      2028: '2028-12-12',
    };
    firstCandle.forEach((gYear, expected) {
      final hy = HebrewCalendar.hebrewYearForHanukkahIn(gYear);
      final kislev25 = HebrewCalendar.gregorianFromHebrew(hy, 9, 25);
      expect(ymd(kislev25.subtract(const Duration(days: 1))), expected,
          reason: 'Hanukkah $gYear');
    });
  });

  test('Kislev 5787 has 30 days', () {
    expect(HebrewCalendar.daysInMonth(HebrewMonth.kislev, 5787), 30);
  });

  test('year lengths are always valid', () {
    for (var y = 5780; y < 5800; y++) {
      expect(const {353, 354, 355, 383, 384, 385}
          .contains(HebrewCalendar.daysInYear(y)), isTrue,
          reason: 'year $y');
    }
  });
}
