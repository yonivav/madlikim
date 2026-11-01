import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/app.dart';
import 'package:madlikim/core/place.dart';
import 'package:madlikim/data/local_store.dart';
import 'package:madlikim/models/user_profile.dart';
import 'package:madlikim/notifications/notification_planner.dart';
import 'package:madlikim/notifications/notification_service.dart';
import 'package:madlikim/social/local_social_repository.dart';
import 'package:madlikim/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

class FakeNotifications extends NotificationService {
  List<PlannedNotification> scheduled = [];

  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleAll(List<PlannedNotification> planned) async =>
      scheduled = planned;
  @override
  Future<void> cancel(int id) async =>
      scheduled.removeWhere((n) => n.id == id);
  @override
  Future<void> cancelAll() async => scheduled = [];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<void> showNow(String title, String body) async {}
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  DateTime il(int y, int m, int d, int h) =>
      tz.TZDateTime(tz.getLocation('Asia/Jerusalem'), y, m, d, h).toUtc();

  Future<(ProviderContainer, FakeNotifications)> boot(
    WidgetTester tester, {
    required DateTime now,
    UserProfile? profile,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    if (profile != null) await store.saveProfile(profile);
    final notifications = FakeNotifications();
    await tester.pumpWidget(ProviderScope(overrides: [
      localStoreProvider.overrideWithValue(store),
      contentProvider.overrideWithValue(loadContent()),
      socialProvider.overrideWithValue(LocalSocialRepository(prefs)),
      notificationServiceProvider.overrideWithValue(notifications),
      clockProvider.overrideWithValue(() => now),
    ], child: const MadlikimApp(listenToLinks: false)));
    await tester.pump(const Duration(milliseconds: 100));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MadlikimApp)));
    return (container, notifications);
  }

  const profile = UserProfile(
    displayName: 'אבי',
    addressForm: AddressForm.male,
    place: Cities.telAviv,
  );

  testWidgets('first launch shows onboarding', (tester) async {
    await boot(tester, now: il(2026, 11, 1, 12));
    expect(find.textContaining('איך לקרוא לך'), findsOneWidget);
  });

  testWidgets('weeknight in the window: big button, mark lit, celebrate',
      (tester) async {
    final (container, notifications) =
        await boot(tester, now: il(2026, 12, 7, 18), profile: profile);
    expect(find.textContaining('ערב טוב', findRichText: true), findsOneWidget);
    expect(find.text('מדליקים'), findsOneWidget);
    expect(notifications.scheduled, isNotEmpty);

    await tester.tap(find.text('מדליקים'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('נר רביעי'), findsWidgets);
    expect(find.text('הדלקתי'), findsOneWidget);

    await tester.tap(find.text('הדלקתי'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('+4'), findsOneWidget);
    expect(container.read(litNightsProvider), {4});

  });

  testWidgets('Shabbat shows only "שבת שלום"', (tester) async {
    await boot(tester, now: il(2026, 12, 5, 12), profile: profile);
    expect(find.text('שבת שלום'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('countdown before Hanukkah', (tester) async {
    await boot(tester, now: il(2026, 11, 20, 12), profile: profile);
    expect(find.textContaining('ימים לחנוכה'), findsOneWidget);
  });
}
