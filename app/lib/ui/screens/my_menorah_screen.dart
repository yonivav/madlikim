import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/my_neri.dart';
import '../widgets/neri.dart';
import '../widgets/scene.dart';
import 'lighting_screen.dart';

/// Vision 28.8, as "Neri's gang": every lit night wakes up a buddy.
class MyMenorahScreen extends ConsumerWidget {
  const MyMenorahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonProvider);
    final lit = ref.watch(litNightsProvider);
    final score = ref.watch(scoreProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final tonight = ref.watch(phaseProvider).night?.number;
    final buddy = (MediaQuery.sizeOf(context).width - 100) / 8;

    NeriMood moodFor(HanukkahNight n) {
      if (lit.contains(n.number)) return NeriMood.happy;
      if (n.number == tonight) return NeriMood.excited;
      if (n.hasStarted(now)) return NeriMood.calm; // missed: no judgment
      return NeriMood.sleep;
    }

    return Scaffold(
      appBar: AppBar(title: Text('החבר\'ה של ${ref.watch(myNeriProvider).name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          Center(child: Text('כל לילה שמדליקים, מתעורר חבר חדש', style: AppText.small)),
          const SizedBox(height: 14),
          Container(
            height: buddy * 1.5 + 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(56),
              border: const Border.fromBorderSide(
                  BorderSide(color: Color(0x2EFFFFFF), width: 1.5)),
              boxShadow: Gloss.glow(AppColors.night, 12),
            ),
            child: NightBackdrop(
              child: Stack(
                children: [
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    height: 12,
                    child: GlossBox(decoration: Gloss.honey(lift: 4), shine: .7),
                  ),
                  Positioned(
                    left: 30,
                    right: 30,
                    bottom: 34,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final n in season.nights)
                          Neri(
                            size: buddy,
                            color: NeriColor.forNight(n.number),
                            mood: moodFor(n),
                            lit: lit.contains(n.number),
                            glow: .55,
                            animate: n.number == tonight,
                            semanticLabel: '${n.title}: ${lit.contains(n.number) ? 'דולק' : 'עוד לא'}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(value: '${score.light}', label: 'אור', gold: true),
              _Stat(value: '${score.nightsLit}/8', label: 'לילות'),
              _Stat(value: '🔥 ${score.currentStreak}', label: 'ברצף'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('הלילות', style: AppText.title),
          const SizedBox(height: 10),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: Column(
              children: [
                for (final night in season.nights)
                  HairlineRow(
                    first: night.number == 1,
                    leading: Neri(
                      size: 26,
                      color: NeriColor.forNight(night.number),
                      mood: moodFor(night),
                      lit: lit.contains(night.number),
                      glow: .4,
                      animate: false,
                    ),
                    title: night.title,
                    subtitle: '${night.hebrewDateLabel}, ${night.day}.${night.month}',
                    trailing: lit.contains(night.number)
                        ? const Icon(Icons.check_circle, color: AppColors.olive)
                        : night.hasStarted(now)
                            ? const Icon(Icons.chevron_left, color: AppColors.muted)
                            : const SizedBox.shrink(),
                    onTap: night.hasStarted(now) && !lit.contains(night.number)
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LightingScreen(night: night)))
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('תגים', style: AppText.title),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 4,
            runSpacing: 14,
            children: [
              for (final b in Achievement.values)
                Tooltip(
                  message: badgeInfo[b]!.howTo,
                  triggerMode: TooltipTriggerMode.tap,
                  child: OlivePill(
                    emoji: badgeInfo[b]!.emoji,
                    text: badgeInfo[b]!.title,
                    earned: score.badges.contains(b),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'לבד אפשר להגיע ל־${HanukkahSeason.maxLight} אור (1+2+…+8). '
            'אורחים וחברים שמצטרפים מוסיפים עוד.',
            style: AppText.small,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.gold = false});
  final String value;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) => GlossBox(
        width: 96,
        height: 96,
        decoration: gold
            ? Gloss.honey(shape: BoxShape.circle)
            : Gloss.pearl(shape: BoxShape.circle),
        shine: gold ? .55 : .9,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                textDirection: TextDirection.ltr,
                style: AppText.numeral.copyWith(fontSize: 26)),
            Text(label,
                style: AppText.small.copyWith(
                    color: gold ? const Color(0xFF7A4A00) : AppColors.muted)),
          ],
        ),
      );
}
