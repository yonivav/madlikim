import 'package:timezone/timezone.dart' as tz;

import '../content/content.dart';
import '../core/hanukkah.dart';
import '../core/zmanim.dart';
import '../models/user_profile.dart';

enum NotificationKind { eve, friNoon, main, second, after }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    this.night,
  });

  final int id;
  final NotificationKind kind;

  /// UTC instant.
  final DateTime at;
  final String title;
  final String body;
  final int? night;

  /// Payload passed back when the notification is tapped.
  String get payload => night == null ? kind.name : '${kind.name}:$night';

  @override
  String toString() => '$kind n=$night at=$at "$title"';
}

/// Builds the full list of local notifications for one season
/// (Vision, chapter 30). Pure: no plugins, fully testable.
class NotificationPlanner {
  NotificationPlanner(this.content);

  final ContentBook content;

  static int idFor(int hebrewYear, int night, NotificationKind kind) =>
      (hebrewYear % 100) * 1000 + night * 10 + kind.index;

  List<PlannedNotification> plan({
    required HanukkahSeason season,
    required UserProfile profile,
    required DateTime now,
    Set<int> litNights = const {},
  }) {
    final place = profile.place;
    final loc = tz.getLocation(place.timeZone);
    final form = profile.addressForm;
    final r = profile.reminders;
    final out = <PlannedNotification>[];
    String hhmm(DateTime utc) {
      final l = tz.TZDateTime.from(utc, loc);
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    // Eve: the day before night 1, at 20:00 (or Friday 11:00 if that is Shabbat).
    final first = season.first;
    var eveAt = first.zmanim
        .atLocal(20)
        .subtract(const Duration(days: 1));
    if (ShabbatClock.isShabbat(eveAt, place)) {
      eveAt = eveAt.subtract(const Duration(hours: 9));
    }
    out.add(PlannedNotification(
      id: idFor(season.hebrewYear, 0, NotificationKind.eve),
      kind: NotificationKind.eve,
      at: eveAt,
      title: content.text('notifications.eve.title', form: form),
      body: content.text('notifications.eve.body', form: form),
    ));

    for (final night in season.nights) {
      final vars = {'title': night.title, 'name': profile.displayName};
      final z = night.zmanim;

      // Friday noon heads-up.
      if (night.kind == NightKind.erevShabbat) {
        out.add(PlannedNotification(
          id: idFor(season.hebrewYear, night.number, NotificationKind.friNoon),
          kind: NotificationKind.friNoon,
          night: night.number,
          at: z.atLocal(12),
          title: content.text('notifications.friNoon.title', form: form),
          body: content.text('notifications.friNoon.body',
              form: form, vars: {...vars, 'time': hhmm(z.candleLighting)}),
        ));
      }

      // Main reminder.
      final DateTime mainAt = switch (night.kind) {
        NightKind.erevShabbat =>
          z.candleLighting.subtract(const Duration(minutes: 60)),
        NightKind.motzeiShabbat =>
          z.shabbatEnd.add(const Duration(minutes: 5)),
        NightKind.weekday => switch (r.mode) {
            ReminderMode.sunset => z.sunset,
            ReminderMode.tzeit => z.tzeit,
            ReminderMode.fixed => z.atLocal(r.fixedHour, r.fixedMinute),
          },
      };
      String title;
      String body;
      if (night.isLast) {
        title = content.text('notifications.last.title', form: form);
        body = content.text('notifications.last.body', form: form);
        if (night.kind == NightKind.erevShabbat) {
          body =
              '$body ${content.text('notifications.mainFriday.body', form: form, vars: {...vars, 'time': hhmm(z.candleLighting)})}';
        }
      } else if (night.kind == NightKind.erevShabbat) {
        title = content.text('notifications.mainFriday.title',
            form: form, vars: vars);
        body = content.text('notifications.mainFriday.body',
            form: form, vars: {...vars, 'time': hhmm(z.candleLighting)});
      } else if (night.kind == NightKind.motzeiShabbat) {
        title = content.text('notifications.mainMotzash.title',
            form: form, vars: vars);
        body = content.text('notifications.mainMotzash.body',
            form: form, vars: vars);
      } else {
        title =
            content.text('notifications.main.title', form: form, vars: vars);
        body = content.text('notifications.main.bodies',
            form: form, vars: vars, index: night.number - 1);
      }
      out.add(PlannedNotification(
        id: idFor(season.hebrewYear, night.number, NotificationKind.main),
        kind: NotificationKind.main,
        night: night.number,
        at: mainAt,
        title: title,
        body: body,
      ));

      // Second reminder: +2.5h, capped at 22:30, never on Friday.
      if (r.secondReminder &&
          night.kind != NightKind.erevShabbat &&
          !litNights.contains(night.number)) {
        var secondAt = mainAt.add(const Duration(minutes: 150));
        final cap = z.atLocal(22, 30);
        if (secondAt.isAfter(cap)) secondAt = cap;
        if (secondAt.isAfter(mainAt.add(const Duration(minutes: 30)))) {
          out.add(PlannedNotification(
            id: idFor(season.hebrewYear, night.number, NotificationKind.second),
            kind: NotificationKind.second,
            night: night.number,
            at: secondAt,
            title: content.text('notifications.second.title', form: form),
            body: content.text('notifications.second.body',
                form: form, vars: vars),
          ));
        }
      }
    }

    // The evening after Hanukkah ends: 19:00 two days after night 8's date.
    var afterAt = season.last.zmanim.atLocal(19).add(const Duration(days: 2));
    if (ShabbatClock.isShabbat(afterAt, place)) {
      afterAt = afterAt.add(const Duration(days: 1));
    }
    out.add(PlannedNotification(
      id: idFor(season.hebrewYear, 9, NotificationKind.after),
      kind: NotificationKind.after,
      at: afterAt,
      title: content.text('notifications.after.title', form: form),
      body: content.text('notifications.after.body', form: form),
    ));

    // Iron rules: nothing in the past, nothing on Shabbat.
    return out
        .where((n) => n.at.isAfter(now))
        .where((n) => !ShabbatClock.isShabbat(n.at, place))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }
}
