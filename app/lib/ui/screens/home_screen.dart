import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_phase.dart';
import '../../core/hanukkah.dart';
import '../../core/hebrew_calendar.dart';
import '../../core/hebrew_numerals.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/my_neri.dart';
import '../widgets/neri.dart';
import '../widgets/scene.dart';
import 'invite_screens.dart';
import 'lighting_screen.dart';
import 'settings_screen.dart';
import 'shell.dart';
import 'songs_screen.dart';

/// Neri in the middle, light rising behind him night by night, one big
/// action. Modeled on the "mascot + level" home of hydration apps.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openLighting(BuildContext context, WidgetRef ref, HanukkahNight n) {
    ref
        .read(localStoreProvider)
        .logEvent('lighting_screen_open', {'night': n.number, 'source': 'home'});
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LightingScreen(night: n)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(phaseProvider);
    final content = ref.watch(contentProvider);
    final profile = ref.watch(profileProvider)!;
    final place = profile.place;
    final score = ref.watch(scoreProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final night = snap.night;

    // Hebrew date tile: tonight's date during Hanukkah, today's otherwise.
    String tileDay, tileMonth;
    if (night != null) {
      tileDay = hebrewNumeral(night.hebrewDay);
      tileMonth = hebrewMonthName(night.hebrewMonth);
    } else {
      final local = tz.TZDateTime.from(now, tz.getLocation(place.timeZone));
      final h = HebrewCalendar.hebrewFromDate(local);
      tileDay = hebrewNumeral(h.day);
      tileMonth = hebrewMonthName(h.month, leapYear: HebrewCalendar.isLeapYear(h.year));
    }

    final buddy = ref.watch(myNeriProvider);
    String neri(String key, {Map<String, Object?> vars = const {}}) => buddyLine(
        content, buddy, key,
        form: profile.addressForm, vars: vars, index: night?.number ?? 0);

    late String title;
    late String bubble;
    var mood = NeriMood.happy;
    var arms = NeriArms.down;
    var lit = false;
    Widget? action;

    switch (snap.phase) {
      case AppPhase.offSeason:
        title = content.text('home.offSeason');
        bubble = neri('offSeason');
        mood = NeriMood.sleep;
        action = BrassButton(
          label: 'להתכונן: הברכות וסדר ההדלקה',
          ghost: true,
          onPressed: () => _openLighting(context, ref, snap.season.first),
        );
      case AppPhase.countdown:
        title = '${snap.daysUntilStart} ימים לחנוכה';
        bubble = neri('countdown', vars: {'count': snap.daysUntilStart});
        arms = NeriArms.wave;
        action = BrassButton(
          label: 'להתכונן: הברכות וסדר ההדלקה',
          ghost: true,
          onPressed: () => _openLighting(context, ref, snap.season.first),
        );
      case AppPhase.eveOfHanukkah:
        title = 'מחר מתחילים';
        bubble = neri('eve');
        mood = NeriMood.excited;
        arms = NeriArms.wave;
        action = BrassButton(
          label: 'ללמוד את הברכות מראש',
          ghost: true,
          onPressed: () => _openLighting(context, ref, snap.season.first),
        );
      case AppPhase.hanukkahDay:
        final n = night!;
        title = n.title;
        bubble = n.kind == NightKind.erevShabbat
            ? neri('windowFriday')
            : neri('today', vars: {'title': n.title, 'time': hhmm(n.windowStart, place)});
        action = BrassButton(
          label: 'לראות מה עושים',
          ghost: true,
          onPressed: () => _openLighting(context, ref, n),
        );
      case AppPhase.lightingWindow:
        final n = night!;
        title = n.title;
        bubble = n.kind == NightKind.erevShabbat
            ? neri('windowFriday')
            : neri('window', vars: {'title': n.title});
        mood = NeriMood.excited;
        arms = NeriArms.up;
        action = BrassButton(
          label: 'מדליקים',
          emoji: '🔥',
          onPressed: () => _openLighting(context, ref, n),
        );
      case AppPhase.litTonight:
        final n = night!;
        title = n.isLast ? 'וזאת חנוכה' : n.title;
        bubble = n.isLast ? neri('litLast') : neri('lit');
        lit = true;
        arms = NeriArms.up;
        action = BrassButton(
          label: 'מעוז צור, עם אקורדים',
          ghost: true,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SongsScreen())),
        );
      case AppPhase.afterHanukkah:
        title = 'חנוכה שמח';
        bubble = neri('after', vars: {'nights': score.nightsLit});
        lit = score.nightsLit > 0;
        mood = NeriMood.wink;
        action = BrassButton(
          label: 'לשתף את הסיכום',
          icon: Icons.ios_share,
          onPressed: () {
            ref.read(localStoreProvider).logEvent('share_tapped', {'kind': 'summary'});
            shareText(content.text('share.summary', vars: {
              'nights': score.nightsLit,
              'light': score.light,
              'link': content.appLink,
            }));
          },
        );
      case AppPhase.shabbat:
        title = content.text('home.shabbat');
        bubble = '';
        mood = NeriMood.sleep;
    }

    final subtitle = score.nightsLit == 0
        ? '${greeting(now, place)}, ${profile.displayName}'
        : '${score.nightsLit} מתוך 8 לילות, ${score.light} אור';
    // The light starts as a glow at the bottom and rises with every night.
    final level = .14 + .86 * score.nightsLit / 8;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                DateTile(day: tileDay, month: tileMonth),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.display),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.small),
                    ],
                  ),
                ),
                if (score.currentStreak >= 2) ...[
                  InkChip(text: '🔥 ${score.currentStreak}'),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  tooltip: 'הגדרות',
                  icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          if (bubble.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
              child: SpeechBubble(bubble),
            ),
          SizedBox(
            height: 330,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(top: 20, child: LightLevel(fraction: level)),
                const Positioned(right: -10, bottom: 0, child: OliveBranch()),
                const Positioned(left: -10, bottom: 0, child: OliveBranch(flip: true)),
                Positioned(
                  bottom: 14,
                  child: MyNeri(
                    size: 180,
                    mood: mood,
                    arms: arms,
                    lit: lit,
                    semanticLabel: '${buddy.name}, $bubble',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAction(
                emoji: '🎶',
                label: 'שירים',
                onTap: () => ref.read(shellTabProvider.notifier).state = 3,
              ),
              const SizedBox(width: 14),
              CircleAction(
                emoji: '👨‍👩‍👧',
                label: 'החבר\'ה',
                onTap: () => ref.read(shellTabProvider.notifier).state = 2,
              ),
              const SizedBox(width: 14),
              CircleAction(
                emoji: '🏠',
                label: 'להזמין',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const InviteCreateScreen())),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
            child: action,
          ),
        ],
      ),
    );
  }
}
