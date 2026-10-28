import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_phase.dart';
import '../../core/hanukkah.dart';
import '../../social/social_models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import 'faq_screen.dart';
import 'groups_screen.dart';
import 'invite_screens.dart';
import 'lighting_screen.dart';
import 'my_menorah_screen.dart';
import 'settings_screen.dart';
import 'shabbat_view.dart';
import 'songs_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(phaseProvider);
    if (snap.phase == AppPhase.shabbat) {
      return ShabbatView(endsAt: snap.shabbatEndsAt);
    }
    final profile = ref.watch(profileProvider)!;
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${greeting(now, profile.place)}, ${profile.displayName}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'הגדרות',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TonightCard(snap: snap),
            const SizedBox(height: 16),
            const _MiniMenorahCard(),
            const SizedBox(height: 16),
            const _FriendsCard(),
            const SizedBox(height: 16),
            const _InviteCard(),
            const SizedBox(height: 16),
            SectionCard(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.gold),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('למה ואיך',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_left),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TonightCard extends ConsumerWidget {
  const _TonightCard({required this.snap});
  final PhaseSnapshot snap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(profileProvider)!;
    final place = profile.place;
    final night = snap.night;

    void openLighting(HanukkahNight n) {
      ref
          .read(localStoreProvider)
          .logEvent('lighting_screen_open', {'night': n.number, 'source': 'home'});
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => LightingScreen(night: n)));
    }

    String title;
    String? subtitle;
    Widget? action;

    switch (snap.phase) {
      case AppPhase.offSeason:
        title = content.text('home.offSeason');
        subtitle = 'עוד ${snap.daysUntilStart} ימים · '
            'נר ראשון ב-${snap.season.first.day}.${snap.season.first.month}';
      case AppPhase.countdown:
        title = content.text('home.countdown',
            vars: {'count': snap.daysUntilStart});
        subtitle = say(profile.addressForm,
            m: 'יש לך נרות בבית? זה הזמן לקנות, לפני שנגמרים בסופר.',
            f: 'יש לך נרות בבית? זה הזמן לקנות, לפני שנגמרים בסופר.',
            p: 'יש נרות בבית? זה הזמן לקנות, לפני שנגמרים בסופר.');
      case AppPhase.eveOfHanukkah:
        title = content.text('home.eve');
        final first = snap.season.first;
        subtitle = 'מחר: נר ראשון, מדליקים מ-${hhmm(first.windowStart, place)}. '
            'צריך: נרות, חנוכייה, גפרורים 🕯️';
        action = OutlinedButton(
          onPressed: () => openLighting(first),
          child: const Text('ללמוד את הברכות מראש'),
        );
      case AppPhase.hanukkahDay:
        final n = night!;
        title = content.text('home.today', vars: {'title': n.title});
        subtitle = switch (n.kind) {
          NightKind.erevShabbat =>
            'ערב שבת: מדליקים לפני ${hhmm(n.preferredUntil, place)}',
          NightKind.motzeiShabbat =>
            'מדליקים אחרי צאת השבת, ${hhmm(n.windowStart, place)}',
          NightKind.weekday => 'מדליקים מ-${hhmm(n.windowStart, place)}',
        };
        action = OutlinedButton(
          onPressed: () => openLighting(n),
          child: const Text('לראות מה עושים'),
        );
      case AppPhase.lightingWindow:
        final n = night!;
        title = content.text('home.window', vars: {'title': n.title});
        subtitle = n.kind == NightKind.erevShabbat
            ? 'כניסת שבת ב-${hhmm(n.preferredUntil, place)}'
            : '${n.number} נרות + שמש';
        action = FilledButton.icon(
          onPressed: () => openLighting(n),
          icon: const Icon(Icons.local_fire_department),
          label: const Text('מדליקים'),
        );
      case AppPhase.litTonight:
        final n = night!;
        title = content.text('home.lit', vars: {'title': n.title});
        subtitle = n.isLast
            ? 'וזאת חנוכה. סיימת יפה 🕎'
            : 'החנוכייה שלך מאירה. נתראה מחר בערב.';
        action = OutlinedButton(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SongsScreen())),
          child: const Text('הנרות הללו / מעוז צור'),
        );
      case AppPhase.afterHanukkah:
        final score = ref.watch(scoreProvider);
        title = content.text('home.after');
        subtitle = 'הדלקת ${score.nightsLit} מתוך 8 לילות · ${score.light} אור';
        action = OutlinedButton.icon(
          onPressed: () => shareText(content.text('share.summary', vars: {
            'nights': score.nightsLit,
            'light': score.light,
            'link': content.appLink,
          })),
          icon: const Icon(Icons.share),
          label: const Text('לשתף את הסיכום'),
        );
      case AppPhase.shabbat:
        title = content.text('home.shabbat');
    }

    return SectionCard(
      highlight: snap.phase == AppPhase.lightingWindow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (night != null)
            Text(night.hebrewDateLabel,
                style: const TextStyle(color: AppColors.muted)),
          Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(fontSize: 16, color: AppColors.silver)),
          ],
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }
}

class _MiniMenorahCard extends ConsumerWidget {
  const _MiniMenorahCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lit = ref.watch(litNightsProvider);
    final score = ref.watch(scoreProvider);
    final positions = {for (final n in lit) n - 1};
    return SectionCard(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MyMenorahScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('החנוכייה שלי',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              Text('${score.light} אור ✨',
                  style: const TextStyle(color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 8),
          Menorah(
            placed: positions,
            lit: positions,
            shamashLit: positions.isNotEmpty,
            height: 110,
          ),
        ],
      ),
    );
  }
}

class _FriendsCard extends ConsumerWidget {
  const _FriendsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider).valueOrNull ?? const [];
    final text = groups.isEmpty
        ? 'פותחים חנוכייה משותפת עם המשפחה או החבר\'ה. כל הדלקה של מישהו מוסיפה אור.'
        : groups.length == 1
            ? '${groups.first.emoji} ${groups.first.name} · ${groups.first.totalLight} אור'
            : '${groups.length} חנוכיות משותפות';
    return SectionCard(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GroupsScreen())),
      child: Row(
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('החבר\'ה',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: AppColors.silver)),
              ],
            ),
          ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(myInvitesProvider).valueOrNull ?? const [];
    final season = ref.watch(seasonProvider);
    final next = invites.isEmpty ? null : invites.first;
    return SectionCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => next == null
              ? const InviteCreateScreen()
              : const InvitesListScreen())),
      child: Row(
        children: [
          const Text('🏠', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('בואו להדליק אצלי',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  next == null
                      ? 'מזמינים חברים לערב אחד של חנוכה. סופגניות אופציונליות (אבל מומלצות).'
                      : '${season.night(next.night).title} ב-${next.time} · '
                          '${next.count(RsvpStatus.yes)} מגיעים',
                  style: const TextStyle(color: AppColors.silver),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}
