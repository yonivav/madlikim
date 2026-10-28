import 'dart:math' as math;

/// Sunrise / sunset / twilight times using the NOAA solar position
/// equations. Accurate to about a minute for the latitudes we care about.
class SunCalculator {
  /// Geometric sunset: sun's upper limb on the horizon, with refraction.
  static const double sunsetDepression = 0.833;

  /// Tzeit hakochavim as used by many Israeli calendars.
  static const double tzeitDepression = 8.5;

  /// Returns the UTC moment the sun crosses [depression] degrees below the
  /// horizon on the civil date [year]-[month]-[day] at [lat]/[lng] (degrees,
  /// east positive). [setting] picks the evening crossing. Returns null when
  /// the sun never reaches that depression (polar regions).
  static DateTime? sunTime({
    required int year,
    required int month,
    required int day,
    required double lat,
    required double lng,
    required double depression,
    bool setting = true,
  }) {
    final jd0 = _julianDay(year, month, day);
    var minutes = 720.0; // start the iteration at UTC noon
    for (var i = 0; i < 3; i++) {
      final jd = jd0 + minutes / 1440.0;
      final t = (jd - 2451545.0) / 36525.0;

      final l0 = _mod(280.46646 + t * (36000.76983 + 0.0003032 * t), 360);
      final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
      final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
      final c = math.sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
          math.sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
          math.sin(_rad(3 * m)) * 0.000289;
      final trueLong = l0 + c;
      final omega = 125.04 - 1934.136 * t;
      final lambda = trueLong - 0.00569 - 0.00478 * math.sin(_rad(omega));
      final eps0 = 23 +
          (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) /
              60;
      final eps = eps0 + 0.00256 * math.cos(_rad(omega));
      final decl =
          _deg(math.asin(math.sin(_rad(eps)) * math.sin(_rad(lambda))));

      final y = math.pow(math.tan(_rad(eps / 2)), 2).toDouble();
      final eqTime = 4 *
          _deg(y * math.sin(2 * _rad(l0)) -
              2 * e * math.sin(_rad(m)) +
              4 * e * y * math.sin(_rad(m)) * math.cos(2 * _rad(l0)) -
              0.5 * y * y * math.sin(4 * _rad(l0)) -
              1.25 * e * e * math.sin(2 * _rad(m)));

      final zenith = 90 + depression;
      final cosH = (math.cos(_rad(zenith)) -
              math.sin(_rad(lat)) * math.sin(_rad(decl))) /
          (math.cos(_rad(lat)) * math.cos(_rad(decl)));
      if (cosH < -1 || cosH > 1) return null;
      var h = _deg(math.acos(cosH));
      if (!setting) h = -h;
      minutes = 720 - 4 * (lng - h) - eqTime;
    }
    final whole = minutes.round();
    return DateTime.utc(year, month, day).add(Duration(minutes: whole));
  }

  static double _julianDay(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _mod(double a, double b) => ((a % b) + b) % b;
}
