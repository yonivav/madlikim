import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_phase.dart';
import '../../core/hanukkah.dart';
import '../../social/social_models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/avatars.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import '../widgets/window_scene.dart';
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
    final lit = ref.watch(litNightsProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          WindowScene(
            overlay: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: profile.displayName.isEmpty
                            ? greeting(now, profile.place)
                            : '${greeting(now, profile.place)}, ',
                        style: AppText.small.copyWith(fontSize: 15),
                        children: profile.displayName.isEmpty
                            ? null
                            : [
                                TextSpan(
                                  text: profile.displayName,
                                  style: const TextStyle(
                                      color: AppColors.parch,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'הגדרות',
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0x0FF3E9D7)),
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.mist, size: 20),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),
            child: _sceneMenorah(snap, lit),
          ),
          _Tonight(snap: snap),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 40),
            child: _Rows(),
          ),
        ],
      ),
    );
  }

  /// What stands on the windowsill depends on the moment.
  Widget _sceneMenorah(PhaseSnapshot snap, Set<int> lit) {
    final n = snap.night;
    switch (snap.phase) {
      case AppPhase.lightingWindow:
      case AppPhase.hanukkahDay:
        return Menorah(
          placed: {for (var i = 0; i < n!.number; i++) i},
          height: 230,
          glow: .35,
        );
      case AppPhase.litTonight:
        final all = {for (var i = 0; i < n!.number; i++) i};
        return Menorah(placed: all, lit: all, shamashLit: true, height: 230);
      case AppPhase.afterHanukkah:
        final positions = {for (final x in lit) x - 1};
        return Menorah(
            placed: positions,
            lit: positions,
            shamashLit: positions.isNotEmpty,
            height: 230,
            glow: .6);
      default:
        return const Menorah(height: 230);
    }
  }
}

class _Tonight extends ConsumerWidget {
  const _Tonight({required this.snap});
  final PhaseSnapshot snap;

  void _openLighting(BuildContext context, WidgetRef ref, HanukkahNight n) {
    ref
        .read(localStoreProvider)
        .logEvent('lighting_screen_open', {'night': n.number, 'source': 'home'});
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LightingScreen(night: n)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(profileProvider)!;
    final place = profile.place;
    final night = snap.night;

    String mark; // the big brass thing on the right
    String title;
    String? sub;
    InlineSpan? when;
    Widget? action;

    TextSpan time(String t) => TextSpan(
        text: t,
        style: const TextStyle(
            color: AppColors.flame, fontWeight: FontWeight.w700));

    switch (snap.phase) {
      case AppPhase.offSeason:
      case AppPhase.countdown:
        mark = '${snap.daysUntilStart}';
        title = snap.phase == AppPhase.countdown
            ? 'ימים לחנוכה'
            : content.text('home.offSeason');
        sub = 'נר ראשון ב־${snap.season.first.day}.${snap.season.first.month}';
        if (snap.phase == AppPhase.countdown) {
          when = TextSpan(
              text: say(profile.addressForm,
                  m: 'יש לך נרות בבית? זה הזמן לקנות.',
                  f: 'יש לך נרות בבית? זה הזמן לקנות.',
                  p: 'יש נרות בבית? זה הזמן לקנות.'));
        }
      case AppPhase.eveOfHanukkah:
        final first = snap.season.first;
        mark = 'מחר';
        title = 'מתחילים';
        sub = first.hebrewDateLabel;
        when = TextSpan(children: [
          const TextSpan(text: 'נר ראשון, מדליקים מ־'),
          time(hhmm(first.windowStart, place)),
        ]);
        action = OutlinedButton(
          onPressed: () => _openLighting(context, ref, first),
          child: const Text('ללמוד את הברכות מראש'),
        );
      case AppPhase.hanukkahDay:
        final n = night!;
        mark = nightLetter(n.number);
        title = n.title;
        sub = n.hebrewDateLabel;
        when = switch (n.kind) {
          NightKind.erevShabbat => TextSpan(children: [
              const TextSpan(text: 'ערב שבת: מדליקים לפני '),
              time(hhmm(n.preferredUntil, place)),
            ]),
          NightKind.motzeiShabbat => TextSpan(children: [
              const TextSpan(text: 'מדליקים אחרי צאת השבת, '),
              time(hhmm(n.windowStart, place)),
            ]),
          NightKind.weekday => TextSpan(children: [
              const TextSpan(text: 'מדליקים מ־'),
              time(hhmm(n.windowStart, place)),
            ]),
        };
        action = OutlinedButton(
          onPressed: () => _openLighting(context, ref, n),
          child: const Text('לראות מה עושים'),
        );
      case AppPhase.lightingWindow:
        final n = night!;
        mark = nightLetter(n.number);
        title = n.title;
        sub = n.hebrewDateLabel;
        when = n.kind == NightKind.erevShabbat
            ? TextSpan(children: [
                const TextSpan(text: 'מדליקים עכשיו. כניסת שבת ב־'),
                time(hhmm(n.preferredUntil, place)),
              ])
            : TextSpan(children: [
                const TextSpan(text: 'אפשר להדליק עכשיו. עדיף עד '),
                time(hhmm(n.preferredUntil, place)),
              ]);
        action = BrassButton(
          label: 'מדליקים',
          onPressed: () => _openLighting(context, ref, n),
        );
      case AppPhase.litTonight:
        final n = night!;
        mark = nightLetter(n.number);
        title = n.isLast ? 'וזאת חנוכה' : n.title;
        sub = n.hebrewDateLabel;
        when = TextSpan(
            text: n.isLast
                ? 'כל שמונת הנרות. סיימת יפה.'
                : 'החנוכייה שלך מאירה. נתראה מחר בערב.');
        action = OutlinedButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SongsScreen())),
          icon: const Icon(Icons.music_note_outlined, size: 20),
          label: const Text('מעוז צור, עם אקורדים'),
        );
      case AppPhase.afterHanukkah:
        final score = ref.watch(scoreProvider);
        mark = '${score.nightsLit}';
        title = 'לילות השנה';
        sub = '${score.light} אור';
        when = TextSpan(text: content.text('home.after'));
        action = OutlinedButton.icon(
          onPressed: () {
            ref.read(localStoreProvider).logEvent('share_tapped', {'kind': 'summary'});
            shareText(content.text('share.summary', vars: {
              'nights': score.nightsLit,
              'light': score.light,
              'link': content.appLink,
            }));
          },
          icon: const Icon(Icons.ios_share, size: 20),
          label: const Text('לשתף את הסיכום'),
        );
      case AppPhase.shabbat:
        mark = '';
        title = content.text('home.shabbat');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 84),
                child: Text(
                  mark,
                  textAlign: TextAlign.center,
                  style: mark.length > 2
                      ? AppText.numeral.copyWith(fontSize: 64, height: 1.2)
                      : AppText.numeral,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(title, style: AppText.display.copyWith(fontSize: 32)),
                    if (sub != null) ...[
                      const SizedBox(height: 4),
                      Text(sub, style: AppText.small),
                    ],
                    if (when != null) ...[
                      const SizedBox(height: 10),
                      Text.rich(when, style: AppText.body),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider).valueOrNull ?? const <Group>[];
    final invites =
        ref.watch(myInvitesProvider).valueOrNull ?? const <HostInvite>[];
    final score = ref.watch(scoreProvider);
    final season = ref.watch(seasonProvider);

    void go(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    final next = invites.isEmpty ? null : invites.first;

    return Column(
      children: [
        if (groups.isEmpty)
          HairlineRow(
            first: true,
            title: 'חנוכייה משותפת',
            subtitle: 'עם המשפחה או החבר\'ה. כל מי שמדליק אצלו מוסיף אור.',
            onTap: () => go(const GroupsScreen()),
          )
        else
          _GroupRow(group: groups.first, more: groups.length - 1),
        HairlineRow(
          title: 'בואו להדליק אצלי',
          subtitle: next == null
              ? 'מזמינים חברים לערב אחד, עם סופגניות'
              : '${season.night(next.night).title} ב־${next.time}, '
                  '${next.count(RsvpStatus.yes)} מגיעים',
          onTap: () => go(next == null
              ? const InviteCreateScreen()
              : const InvitesListScreen()),
        ),
        HairlineRow(
          title: 'החנוכייה שלי',
          subtitle: score.nightsLit == 0
              ? 'כאן נאסף האור של כל הלילות'
              : score.currentStreak >= 2
                  ? '${score.light} אור, ${score.currentStreak} לילות ברצף'
                  : '${score.light} אור, ${score.nightsLit} לילות',
          onTap: () => go(const MyMenorahScreen()),
        ),
        HairlineRow(
          title: 'שירים',
          subtitle: 'הנרות הללו, מעוז צור עם אקורדים',
          onTap: () => go(const SongsScreen()),
        ),
        HairlineRow(
          title: 'למה ואיך',
          subtitle: 'שאלות קצרות על ההדלקה',
          onTap: () => go(const FaqScreen()),
        ),
      ],
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group, required this.more});
  final Group group;
  final int more;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(socialNightProvider);
    final data = ref.watch(groupNightProvider((group.id, night))).valueOrNull;
    final litIds = data?.litMemberIds ?? const <String>{};
    final title = more > 0 ? '${group.name} ועוד $more' : group.name;
    return HairlineRow(
      first: true,
      title: title,
      subtitle: '${litIds.length} מתוך ${group.members.length} כבר הדליקו הערב',
      trailing: AvatarStack(members: group.members, litIds: litIds),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              more > 0 ? const GroupsScreen() : GroupScreen(groupId: group.id))),
    );
  }
}
