import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../content/content.dart';
import '../core/app_phase.dart';
import '../core/hanukkah.dart';
import '../core/place.dart';
import '../data/local_store.dart';
import '../logic/scoring.dart';
import '../models/lighting.dart';
import '../models/user_profile.dart';
import '../notifications/notification_planner.dart';
import '../notifications/notification_service.dart';
import '../social/social_models.dart';
import '../social/social_repository.dart';

// ---------------------------------------------------------------------------
// Services (overridden in main.dart and in tests)
// ---------------------------------------------------------------------------

final localStoreProvider =
    Provider<LocalStore>((_) => throw UnimplementedError());
final contentProvider =
    Provider<ContentBook>((_) => throw UnimplementedError());
final socialProvider =
    Provider<SocialRepository>((_) => throw UnimplementedError());
final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

/// The clock. Tests override it to jump to any night of Hanukkah.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Ticks every 30 seconds so the phase moves on its own.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock().toUtc();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock().toUtc());
});

DateTime _now(Ref ref) =>
    ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider)().toUtc();

// ---------------------------------------------------------------------------
// Profile and lightings
// ---------------------------------------------------------------------------

class ProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => ref.read(localStoreProvider).loadProfile();

  Future<void> save(UserProfile profile) async {
    await ref.read(localStoreProvider).saveProfile(profile);
    state = profile;
    await ref.read(appActionsProvider).reschedule();
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

class LightingsNotifier extends Notifier<List<LightingRecord>> {
  @override
  List<LightingRecord> build() => ref.read(localStoreProvider).loadLightings();

  Future<void> add(LightingRecord record) async {
    if (state.any(
        (r) => r.hebrewYear == record.hebrewYear && r.night == record.night)) {
      return;
    }
    state = [...state, record];
    await ref.read(localStoreProvider).saveLightings(state);
  }

  Future<void> clear() async {
    state = [];
    await ref.read(localStoreProvider).saveLightings(state);
  }
}

final lightingsProvider =
    NotifierProvider<LightingsNotifier, List<LightingRecord>>(
        LightingsNotifier.new);

Place _place(Ref ref) => ref.watch(profileProvider)?.place ?? Cities.telAviv;

LightingStart _start(Ref ref) =>
    ref.watch(profileProvider)?.reminders.lightingStart ?? LightingStart.sunset;

// ---------------------------------------------------------------------------
// Season, phase, score
// ---------------------------------------------------------------------------

/// The Hebrew year of the current season. An int, so everything built on it
/// only recomputes when the season actually changes, not every tick.
final seasonYearProvider = Provider<int>((ref) => HanukkahSeason.current(
        _now(ref), _place(ref),
        afterDays: PhaseCalculator.afterDays)
    .hebrewYear);

final seasonProvider = Provider<HanukkahSeason>((ref) =>
    HanukkahSeason.forHebrewYear(ref.watch(seasonYearProvider), _place(ref),
        lightingStart: _start(ref)));

final seasonLightingsProvider = Provider<List<LightingRecord>>((ref) {
  final year = ref.watch(seasonProvider).hebrewYear;
  return ref
      .watch(lightingsProvider)
      .where((r) => r.hebrewYear == year)
      .toList();
});

final litNightsProvider = Provider<Set<int>>(
    (ref) => {for (final r in ref.watch(seasonLightingsProvider)) r.night});

final phaseProvider = Provider<PhaseSnapshot>((ref) => PhaseCalculator.compute(
      now: _now(ref),
      place: _place(ref),
      litNights: ref.watch(litNightsProvider),
      lightingStart: _start(ref),
    ));

final isShabbatProvider =
    Provider<bool>((ref) => ref.watch(phaseProvider).phase == AppPhase.shabbat);

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final year = ref.watch(seasonProvider).hebrewYear;
  return ref.watch(socialProvider).watchMyGroups(year);
});

final myInvitesProvider = StreamProvider<List<HostInvite>>((ref) {
  final year = ref.watch(seasonProvider).hebrewYear;
  return ref.watch(socialProvider).watchMyInvites(year);
});

final scoreProvider = Provider<ScoreSummary>((ref) {
  final season = ref.watch(seasonProvider);
  final now = _now(ref);
  final me = ref.watch(socialProvider).currentUserId;
  final groups = ref.watch(myGroupsProvider).valueOrNull ?? const [];
  final friendsJoined = groups
      .where((g) => g.ownerId == me)
      .fold<int>(0, (s, g) => s + (g.members.length - 1).clamp(0, 999));
  final loc = tz.getLocation(season.first.zmanim.place.timeZone);
  final started = season.nights.where((n) => n.hasStarted(now));
  return Scoring.summarize(
    records: ref.watch(seasonLightingsProvider),
    fridayNights: {
      for (final n in season.nights)
        if (n.kind == NightKind.erevShabbat) n.number,
    },
    friendsJoined: friendsJoined,
    localHourOf: (r) => tz.TZDateTime.from(r.markedAt, loc).hour,
    lastStartedNight: started.isEmpty ? 0 : started.last.number,
  );
});

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

final appActionsProvider = Provider<AppActions>((ref) => AppActions(ref));

class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  LocalStore get _store => _ref.read(localStoreProvider);

  /// Can "הדלקתי" be pressed for [night] right now? (Vision, chapter 29)
  bool canMarkNow(HanukkahNight night) {
    final now = _ref.read(clockProvider)().toUtc();
    if (_ref.read(isShabbatProvider)) return false;
    return night.isInWindow(now);
  }

  /// Can a past night be marked with "שכחתי לסמן"?
  bool canMarkLate(HanukkahNight night) {
    final now = _ref.read(clockProvider)().toUtc();
    if (_ref.read(isShabbatProvider)) return false;
    final season = _ref.read(seasonProvider);
    return !now.isBefore(night.windowEnd) &&
        now.isBefore(season.afterPeriodEnd(PhaseCalculator.afterDays));
  }

  Future<int> markLit(HanukkahNight night,
      {bool withGuests = false, bool late = false}) async {
    final record = LightingRecord(
      hebrewYear: night.hebrewYear,
      night: night.number,
      markedAt: _ref.read(clockProvider)().toUtc(),
      withGuests: withGuests,
      late: late,
    );
    await _ref.read(lightingsProvider.notifier).add(record);
    final light = Scoring.lightFor(record);
    unawaited(_ref
        .read(socialProvider)
        .recordLighting(
            hebrewYear: night.hebrewYear, night: night.number, light: light)
        .catchError((_) {}));
    unawaited(_ref.read(notificationServiceProvider).cancel(
        NotificationPlanner.idFor(
            night.hebrewYear, night.number, NotificationKind.second)));
    await _store.logEvent('lit_marked', {
      'night': night.number,
      'late': late,
      'with_guests': withGuests,
    });
    return light;
  }

  /// Rebuilds every scheduled notification from the current profile.
  Future<void> reschedule() async {
    final profile = _ref.read(profileProvider);
    final service = _ref.read(notificationServiceProvider);
    if (profile == null) {
      await service.cancelAll();
      return;
    }
    final now = _ref.read(clockProvider)().toUtc();
    final season = HanukkahSeason.current(now, profile.place,
        lightingStart: profile.reminders.lightingStart,
        afterDays: PhaseCalculator.afterDays);
    final planned = NotificationPlanner(_ref.read(contentProvider)).plan(
      season: season,
      profile: profile,
      now: now,
      litNights: _ref.read(litNightsProvider),
    );
    try {
      await service.scheduleAll(planned);
    } catch (_) {
      // Notifications are best effort; never crash the app over them.
    }
  }

  Future<bool> requestNotifications() async {
    try {
      return await _ref.read(notificationServiceProvider).requestPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteEverything() async {
    try {
      await _ref.read(socialProvider).deleteEverything();
    } catch (_) {}
    try {
      await _ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {}
    await _store.clearAll();
    _ref.invalidate(profileProvider);
    _ref.invalidate(lightingsProvider);
  }
}
