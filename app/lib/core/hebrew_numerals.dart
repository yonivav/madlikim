/// Small helpers for writing numbers and dates the Hebrew way.
library;

const _ones = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
const _tens = ['', 'י', 'כ', 'ל'];

/// Hebrew numeral with geresh / gershayim for 1..39 (enough for days of a
/// month). 15 and 16 use the traditional ט"ו and ט"ז.
String hebrewNumeral(int n) {
  assert(n >= 1 && n < 40);
  String letters;
  if (n == 15) {
    letters = 'טו';
  } else if (n == 16) {
    letters = 'טז';
  } else {
    letters = _tens[n ~/ 10] + _ones[n % 10];
  }
  if (letters.length == 1) return "$letters'";
  return '${letters.substring(0, letters.length - 1)}"${letters.substring(letters.length - 1)}';
}

const _monthNames = {
  1: 'ניסן',
  2: 'אייר',
  3: 'סיוון',
  4: 'תמוז',
  5: 'אב',
  6: 'אלול',
  7: 'תשרי',
  8: 'חשוון',
  9: 'כסלו',
  10: 'טבת',
  11: 'שבט',
  12: 'אדר',
  13: 'אדר ב',
};

String hebrewMonthName(int month) => _monthNames[month] ?? '';

/// "ראשון", "שני" ... "שמיני" (ordinal, masculine, for "נר ___").
const ordinalsMasculine = [
  '',
  'ראשון',
  'שני',
  'שלישי',
  'רביעי',
  'חמישי',
  'שישי',
  'שביעי',
  'שמיני',
];

/// Weekday names, indexed by [DateTime.weekday] (1 = Monday).
const weekdayNames = {
  DateTime.sunday: 'ראשון',
  DateTime.monday: 'שני',
  DateTime.tuesday: 'שלישי',
  DateTime.wednesday: 'רביעי',
  DateTime.thursday: 'חמישי',
  DateTime.friday: 'שישי',
  DateTime.saturday: 'שבת',
};
