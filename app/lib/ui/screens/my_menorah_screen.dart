import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
    final buddy = (MediaQuery.sizeOf(context).width - 72) / 8;

    NeriMood moodFor(HanukkahNight n) {
      if (lit.contains(n.number)) return NeriMood.happy;
      if (n.number == tonight) return NeriMood.excited;
      if (n.hasStarted(now)) return NeriMood.calm; // missed: no judgment
      return NeriMood.sleep;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('החבר\'ה של נרי')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          Center(child: Text('כל לילה שמדליקים, מתעורר חבר חדש', style: AppText.small)),
          const SizedBox(height: 14),
          Container(
            height: buddy * 1.5 + 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: Ink2.shadow(3, 4),
            ),
            child: NightBackdrop(
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 22,
                    height: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9A441),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 32,
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
            children: [
              _Stat(value: '${score.light}', label: 'אור'),
              const SizedBox(width: 10),
              _Stat(value: '${score.nightsLit}/8', label: 'לילות'),
              const SizedBox(width: 10),
              _Stat(value: '🔥 ${score.currentStreak}', label: 'ברצף'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('הלילות', style: AppText.title),
          const SizedBox(height: 4),
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
          const SizedBox(height: 20),
          const Text('תגים', style: AppText.title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 10,
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
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink, width: 2),
            boxShadow: Ink2.shadow(2, 3),
          ),
          child: Column(
            children: [
              Text(value,
                  textDirection: TextDirection.ltr,
                  style: AppText.numeral.copyWith(fontSize: 26)),
              Text(label, style: AppText.small),
            ],
          ),
        ),
      );
}
