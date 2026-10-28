import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/core/hanukkah.dart';
import 'package:madlikim/core/place.dart';
import 'package:madlikim/core/zmanim.dart';
import 'package:madlikim/models/user_profile.dart';
import 'package:madlikim/notifications/notification_planner.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final early = DateTime.utc(2020);

  List<PlannedNotification> planFor(int hebrewYear, UserProfile profile,
      {DateTime? now, Set<int> lit = const {}}) {
    final season = HanukkahSeason.forHebrewYear(hebrewYear, profile.place,
        lightingStart: profile.reminders.lightingStart);
    return NotificationPlanner(loadContent()).plan(
        season: season, profile: profile, now: now ?? early, litNights: lit);
  }

  const base = UserProfile(displayName: 'אבי', addressForm: AddressForm.male);

  for (final year in [5786, 5787, 5788]) {
    for (final place in [Cities.telAviv, Cities.jerusalem]) {
      for (final mode in ReminderMode.values) {
        test('no notification on Shabbat: $year ${place.id} ${mode.name}', () {
          final profile = base.copyWith(
              place: place,
              reminders: ReminderSettings(mode: mode, fixedHour: 23));
          final plan = planFor(year, profile);
          expect(plan, isNotEmpty);
          for (final n in plan) {
            expect(ShabbatClock.isShabbat(n.at, place), isFalse,
                reason: n.toString());
          }
        });
      }
    }
  }

  test('5787: every night has a main reminder, nights 1 and 8 are early', () {
    final plan = planFor(5787, base);
    final mains = plan.where((n) => n.kind == NotificationKind.main).toList();
    expect([for (final n in mains) n.night], [1, 2, 3, 4, 5, 6, 7, 8]);

    final season = HanukkahSeason.forHebrewYear(5787, Cities.telAviv);
    final fri = mains.first;
    expect(fri.at.isBefore(season.first.zmanim.candleLighting), isTrue);
    expect(mains.last.title, contains('וזאת חנוכה'));
    expect(mains.last.at.isBefore(season.last.zmanim.candleLighting), isTrue);

    // Saturday night reminder comes after Shabbat ends.
    expect(mains[1].at.isAfter(season.night(2).zmanim.shabbatEnd), isTrue);
  });

  test('Friday noon heads-up on both Fridays', () {
    final plan = planFor(5787, base);
    final noons =
        plan.where((n) => n.kind == NotificationKind.friNoon).toList();
    expect([for (final n in noons) n.night], [1, 8]);
  });

  test('no second reminder on Friday, none for nights already lit', () {
    final plan = planFor(5787, base, lit: {3});
    final seconds = {
      for (final n in plan)
        if (n.kind == NotificationKind.second) n.night
    };
    expect(seconds.contains(1), isFalse);
    expect(seconds.contains(8), isFalse);
    expect(seconds.contains(3), isFalse);
    expect(seconds.contains(4), isTrue);
  });

  test('second reminder never after 22:30', () {
    final plan = planFor(5787,
        base.copyWith(
            reminders: const ReminderSettings(
                mode: ReminderMode.fixed, fixedHour: 21, fixedMinute: 0)));
    final loc = tz.getLocation('Asia/Jerusalem');
    for (final n in plan.where((n) => n.kind == NotificationKind.second)) {
      final l = tz.TZDateTime.from(n.at, loc);
      expect(l.hour * 60 + l.minute, lessThanOrEqualTo(22 * 60 + 30));
    }
  });

  test('eve and after notifications exist', () {
    final plan = planFor(5787, base);
    final eve = plan.firstWhere((n) => n.kind == NotificationKind.eve);
    final l = tz.TZDateTime.from(eve.at, tz.getLocation('Asia/Jerusalem'));
    expect(l.day, 3);
    expect(l.hour, 20);
    expect(plan.any((n) => n.kind == NotificationKind.after), isTrue);
  });

  test('nothing in the past', () {
    final now = DateTime.utc(2026, 12, 7, 12);
    final plan = planFor(5787, base, now: now);
    expect(plan.every((n) => n.at.isAfter(now)), isTrue);
    expect(plan.where((n) => n.kind == NotificationKind.main).first.night, 4);
  });

  test('ids are unique and stable', () {
    final plan = planFor(5787, base);
    expect(plan.map((n) => n.id).toSet().length, plan.length);
    expect(NotificationPlanner.idFor(5787, 4, NotificationKind.main),
        87 * 1000 + 40 + NotificationKind.main.index);
  });

  test('texts are filled (no leftover {placeholders})', () {
    for (final n in planFor(5787, base)) {
      expect(n.title.contains('{'), isFalse, reason: n.title);
      expect(n.body.contains('{'), isFalse, reason: n.body);
      expect(n.title, isNotEmpty);
    }
  });
}
