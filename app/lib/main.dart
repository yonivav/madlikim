import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'content/content.dart';
import 'data/local_store.dart';
import 'notifications/notification_service.dart';
import 'social/firebase_social_repository.dart';
import 'social/local_social_repository.dart';
import 'social/social_repository.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
  }

  final prefs = await SharedPreferences.getInstance();
  final content = await ContentBook.load();

  // Firebase is optional: without google-services.json / GoogleService-Info
  // the app runs in local mode (Vision, 34.1).
  SocialRepository social;
  try {
    await Firebase.initializeApp();
    social = FirebaseSocialRepository();
    await social.ensureUser();
  } catch (_) {
    social = LocalSocialRepository(prefs);
  }

  final notifications = NotificationService();
  try {
    await notifications.init();
  } catch (_) {}

  runApp(ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(LocalStore(prefs)),
      contentProvider.overrideWithValue(content),
      socialProvider.overrideWithValue(social),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const MadlikimApp(),
  ));
}
