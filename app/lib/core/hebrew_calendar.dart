/// Hebrew calendar arithmetic (molad + dehiyyot), after Reingold & Dershowitz,
/// "Calendrical Calculations".
///
/// Months are numbered from Nisan = 1, so Tishri = 7, Kislev = 9, Tevet = 10.
/// A "fixed" day number counts days with 1 = January 1, year 1 (proleptic
/// Gregorian).
library;

class HebrewMonth {
  static const nisan = 1;
  static const tishri = 7;
  static const marheshvan = 8;
  static const kislev = 9;
  static const tevet = 10;
  static const adar = 12;
  static const adar2 = 13;
}

class HebrewCalendar {
  static const int _epoch = -1373427; // fixed day of 1 Tishri, AM 1

  static int _mod(int a, int b) => ((a % b) + b) % b;

  static bool isLeapYear(int year) => _mod(7 * year + 1, 19) < 7;

  static int lastMonthOfYear(int year) => isLeapYear(year) ? 13 : 12;

  static int _elapsedDays(int year) {
    final monthsElapsed = (235 * year - 234) ~/ 19;
    final partsElapsed = 12084 + 13753 * monthsElapsed;
    final days = 29 * monthsElapsed + partsElapsed ~/ 25920;
    return _mod(3 * (days + 1), 7) < 3 ? days + 1 : days;
  }

  static int _yearLengthCorrection(int year) {
    final ny0 = _elapsedDays(year - 1);
    final ny1 = _elapsedDays(year);
    final ny2 = _elapsedDays(year + 1);
    if (ny2 - ny1 == 356) return 2;
    if (ny1 - ny0 == 382) return 1;
    return 0;
  }

  /// Fixed day number of Rosh Hashana of [year].
  static int newYear(int year) =>
      _epoch + _elapsedDays(year) + _yearLengthCorrection(year);

  static int daysInYear(int year) => newYear(year + 1) - newYear(year);

  static bool _longMarheshvan(int year) =>
      const {355, 385}.contains(daysInYear(year));

  static bool _shortKislev(int year) =>
      const {353, 383}.contains(daysInYear(year));

  static int daysInMonth(int month, int year) {
    if (const {2, 4, 6, 10, 13}.contains(month) ||
        (month == HebrewMonth.adar && !isLeapYear(year)) ||
        (month == HebrewMonth.marheshvan && !_longMarheshvan(year)) ||
        (month == HebrewMonth.kislev && _shortKislev(year))) {
      return 29;
    }
    return 30;
  }

  /// Fixed day number for a Hebrew date.
  static int fixedFromHebrew(int year, int month, int day) {
    var result = newYear(year) + day - 1;
    if (month < HebrewMonth.tishri) {
      for (var m = HebrewMonth.tishri; m <= lastMonthOfYear(year); m++) {
        result += daysInMonth(m, year);
      }
      for (var m = 1; m < month; m++) {
        result += daysInMonth(m, year);
      }
    } else {
      for (var m = HebrewMonth.tishri; m < month; m++) {
        result += daysInMonth(m, year);
      }
    }
    return result;
  }

  static final DateTime _fixedOne = DateTime.utc(1, 1, 1);

  /// Converts a fixed day number to a UTC midnight [DateTime] (date only).
  static DateTime dateFromFixed(int fixed) =>
      _fixedOne.add(Duration(days: fixed - 1));

  /// Gregorian civil date of a Hebrew date (the daytime part of that day).
  static DateTime gregorianFromHebrew(int year, int month, int day) =>
      dateFromFixed(fixedFromHebrew(year, month, day));

  /// Fixed day number of a civil date.
  static int fixedFromDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_fixedOne).inDays + 1;

  /// Hebrew date of a civil date (the daytime part of that day).
  static ({int year, int month, int day}) hebrewFromDate(DateTime date) {
    final fixed = fixedFromDate(date);
    var year = ((fixed - _epoch) / 365.2468).floor() + 1;
    while (newYear(year + 1) <= fixed) {
      year++;
    }
    while (newYear(year) > fixed) {
      year--;
    }
    final months = [
      for (var m = HebrewMonth.tishri; m <= lastMonthOfYear(year); m++) m,
      for (var m = 1; m < HebrewMonth.tishri; m++) m,
    ];
    for (final m in months) {
      final start = fixedFromHebrew(year, m, 1);
      if (fixed >= start && fixed < start + daysInMonth(m, year)) {
        return (year: year, month: m, day: fixed - start + 1);
      }
    }
    return (year: year, month: HebrewMonth.tishri, day: 1);
  }

  /// The Hebrew year whose Hanukkah falls in December of [gregorianYear]
  /// (or very late November).
  static int hebrewYearForHanukkahIn(int gregorianYear) => gregorianYear + 3761;
}
