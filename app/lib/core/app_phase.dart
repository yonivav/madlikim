import 'hanukkah.dart';
import 'place.dart';
import 'zmanim.dart';

/// The single state the home screen is in (Vision, chapter 26).
enum AppPhase {
  offSeason,
  countdown,
  eveOfHanukkah,
  hanukkahDay,
  lightingWindow,
  litTonight,
  shabbat,
  afterHanukkah,
}

class PhaseSnapshot {
  const PhaseSnapshot({
    required this.phase,
    required this.season,
    this.night,
    this.daysUntilStart,
    this.shabbatEndsAt,
  });

  final AppPhase phase;
  final HanukkahSeason season;

  /// The relevant night (tonight, or the one whose window is open).
  final HanukkahNight? night;

  /// Whole days until the first candle (countdown / off season).
  final int? daysUntilStart;

  final DateTime? shabbatEndsAt;
}

class PhaseCalculator {
  static const countdownDays = 30;
  static const afterDays = 7;

  static PhaseSnapshot compute({
    required DateTime now,
    required Place place,
    required Set<int> litNights,
    LightingStart lightingStart = LightingStart.sunset,
  }) {
    final season = HanukkahSeason.current(now, place,
        lightingStart: lightingStart, afterDays: afterDays);
    final night = season.nightAt(now);

    if (ShabbatClock.isShabbat(now, place)) {
      return PhaseSnapshot(
        phase: AppPhase.shabbat,
        season: season,
        night: night,
        shabbatEndsAt: ShabbatClock.endOfShabbat(now, place),
      );
    }

    final daysUntil = _daysBetween(now, season.first.dayStart);

    if (now.isBefore(season.eveDayStart)) {
      return PhaseSnapshot(
        phase: daysUntil <= countdownDays
            ? AppPhase.countdown
            : AppPhase.offSeason,
        season: season,
        daysUntilStart: daysUntil,
      );
    }
    if (now.isBefore(season.first.dayStart)) {
      return PhaseSnapshot(
          phase: AppPhase.eveOfHanukkah, season: season, daysUntilStart: 1);
    }
    if (night != null) {
      if (litNights.contains(night.number)) {
        return PhaseSnapshot(
            phase: AppPhase.litTonight, season: season, night: night);
      }
      if (night.isInWindow(now)) {
        return PhaseSnapshot(
            phase: AppPhase.lightingWindow, season: season, night: night);
      }
      if (!night.hasStarted(now)) {
        return PhaseSnapshot(
            phase: AppPhase.hanukkahDay, season: season, night: night);
      }
    }
    // Between the last window closing and the end of the "after" period.
    return PhaseSnapshot(phase: AppPhase.afterHanukkah, season: season);
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final diff = to.difference(from);
    if (diff.isNegative) return 0;
    return (diff.inHours / 24).ceil();
  }
}
