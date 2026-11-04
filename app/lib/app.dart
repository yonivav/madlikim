import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'links/deep_links.dart';
import 'state/providers.dart';
import 'ui/screens/groups_screen.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/invite_screens.dart';
import 'ui/screens/lighting_screen.dart';
import 'ui/screens/my_menorah_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MadlikimApp extends StatelessWidget {
  const MadlikimApp({super.key, this.listenToLinks = true});

  /// Tests turn this off (no platform channels there).
  final bool listenToLinks;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מדליקים',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RootGate(listenToLinks: listenToLinks),
    );
  }
}

/// Onboarding until there is a profile, then home. Also routes deep links and
/// notification taps, holding them until onboarding is done.
class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key, this.listenToLinks = true});
  final bool listenToLinks;

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  final List<StreamSubscription<dynamic>> _subs = [];
  DeepLink? _pendingLink;
  String? _pendingPayload;

  @override
  void initState() {
    super.initState();
    if (widget.listenToLinks) _listen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(profileProvider) != null) {
        ref.read(appActionsProvider).reschedule();
      }
    });
  }

  Future<void> _listen() async {
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      if (initial != null) _onLink(initial);
      _subs.add(links.uriLinkStream.listen(_onLink));
    } catch (_) {}
    try {
      final notifications = ref.read(notificationServiceProvider);
      final payload = await notifications.launchPayload();
      if (payload != null) _onPayload(payload);
      _subs.add(notifications.taps.listen(_onPayload));
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _onLink(Uri uri) {
    final link = DeepLink.parse(uri);
    if (link == null) return;
    if (ref.read(profileProvider) == null) {
      _pendingLink = link;
      return;
    }
    _openLink(link);
  }

  void _openLink(DeepLink link) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    switch (link) {
      case JoinGroupLink(:final code):
        nav.push(MaterialPageRoute(
            builder: (_) => JoinGroupScreen(initialCode: code, fromLink: true)));
      case OpenInviteLink(:final inviteId):
        nav.push(MaterialPageRoute(
            builder: (_) => InviteScreen(inviteId: inviteId)));
    }
  }

  void _onPayload(String payload) {
    if (ref.read(profileProvider) == null) {
      _pendingPayload = payload;
      return;
    }
    _openPayload(payload);
  }

  void _openPayload(String payload) {
    final nav = navigatorKey.currentState;
    if (nav == null || ref.read(isShabbatProvider)) return;
    final parts = payload.split(':');
    ref
        .read(localStoreProvider)
        .logEvent('notification_opened', {'kind': parts.first});
    final night = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (night != null && night >= 1 && night <= 8) {
      nav.push(MaterialPageRoute(
          builder: (_) =>
              LightingScreen(night: ref.read(seasonProvider).night(night))));
    } else if (parts.first == 'after') {
      nav.push(MaterialPageRoute(builder: (_) => const MyMenorahScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (prev, next) {
      if (prev == null && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final link = _pendingLink;
          final payload = _pendingPayload;
          _pendingLink = null;
          _pendingPayload = null;
          if (link != null) _openLink(link);
          if (payload != null) _openPayload(payload);
        });
      }
    });
    final profile = ref.watch(profileProvider);
    return profile == null ? const OnboardingScreen() : const Shell();
  }
}
