import '../models/lighting.dart';

/// Badges (Vision, chapter 10.4).
enum Achievement {
  firstLight,
  halfMenorah,
  fullMenorah,
  openHouse,
  bringsFriends,
  notTooLate,
  erevShabbat,
}

class BadgeInfo {
  const BadgeInfo(this.emoji, this.title, this.howTo);
  final String emoji;
  final String title;
  final String howTo;
}

const badgeInfo = <Achievement, BadgeInfo>{
  Achievement.firstLight: BadgeInfo('✨', 'הנר הראשון', 'הדלקה ראשונה'),
  Achievement.halfMenorah: BadgeInfo('🕯️', 'חצי חנוכייה', '4 לילות'),
  Achievement.fullMenorah: BadgeInfo('🕎', 'חנוכייה שלמה', 'כל 8 הלילות'),
  Achievement.openHouse: BadgeInfo('🏠', 'בית פתוח', 'הדלקה עם אורחים'),
  Achievement.bringsFriends:
      BadgeInfo('🤝', 'מביא חברים', '3 אנשים הצטרפו לחנוכייה שפתחת'),
  Achievement.notTooLate: BadgeInfo('🌙', 'עוד לא מאוחר', 'הדלקה אחרי 21:00'),
  Achievement.erevShabbat: BadgeInfo('🕯️🕯️', 'ערב שבת', 'הדלקה בערב שבת'),
};

class ScoreSummary {
  const ScoreSummary({
    required this.light,
    required this.nightsLit,
    required this.currentStreak,
    required this.badges,
  });

  final int light;
  final int nightsLit;
  final int currentStreak;
  final Set<Achievement> badges;
}

class Scoring {
  static const guestsBonus = 2;
  static const friendJoinedBonus = 3;

  /// Light for one night: n candles = n light, plus a bonus for guests.
  static int lightFor(LightingRecord r) =>
      r.night + (r.withGuests ? guestsBonus : 0);

  /// [fridayNights] are the night numbers that fall on a Friday this year.
  /// [lateLocalHour] maps a record to the local hour it was marked (to give
  /// the "not too late" badge only for real-time marks).
  static ScoreSummary summarize({
    required List<LightingRecord> records,
    required Set<int> fridayNights,
    required int friendsJoined,
    int Function(LightingRecord)? localHourOf,
    int? lastStartedNight,
  }) {
    final byNight = {for (final r in records) r.night: r};
    final light = byNight.values.fold<int>(0, (s, r) => s + lightFor(r)) +
        friendsJoined * friendJoinedBonus;

    // Streak: consecutive lit nights ending at the most recent started night
    // (or the most recent lit night if none given). A missed night breaks
    // the count quietly; we never show it as a failure.
    var streak = 0;
    final top = lastStartedNight ??
        (byNight.keys.isEmpty
            ? 0
            : byNight.keys.reduce((a, b) => a > b ? a : b));
    var n = top;
    if (n > 0 && !byNight.containsKey(n)) n--; // tonight not lit yet is fine
    while (n >= 1 && byNight.containsKey(n)) {
      streak++;
      n--;
    }

    final badges = <Achievement>{};
    final count = byNight.length;
    if (count >= 1) badges.add(Achievement.firstLight);
    if (count >= 4) badges.add(Achievement.halfMenorah);
    if (count >= 8) badges.add(Achievement.fullMenorah);
    if (byNight.values.any((r) => r.withGuests)) badges.add(Achievement.openHouse);
    if (friendsJoined >= 3) badges.add(Achievement.bringsFriends);
    if (byNight.keys.any(fridayNights.contains)) badges.add(Achievement.erevShabbat);
    if (localHourOf != null &&
        byNight.values.any((r) {
          if (r.late) return false;
          final h = localHourOf(r);
          return h >= 21 || h < 4;
        })) {
      badges.add(Achievement.notTooLate);
    }

    return ScoreSummary(
      light: light,
      nightsLit: count,
      currentStreak: streak,
      badges: badges,
    );
  }
}
