import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import 'lighting_screen.dart';

/// Vision 28.8: eight nights, light, streak, badges.
class MyMenorahScreen extends ConsumerWidget {
  const MyMenorahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonProvider);
    final lit = ref.watch(litNightsProvider);
    final score = ref.watch(scoreProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final positions = {for (final n in lit) n - 1};

    return Scaffold(
      appBar: AppBar(title: const Text('החנוכייה שלי')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        children: [
          Menorah(
            placed: positions,
            lit: positions,
            shamashLit: positions.isNotEmpty,
            height: 220,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(value: '${score.light}', label: 'אור'),
              _Stat(value: '${score.nightsLit}', label: 'מתוך 8 לילות'),
              _Stat(value: '${score.currentStreak}', label: 'ברצף'),
            ],
          ),
          const SizedBox(height: 28),
          const Text('הלילות', style: AppText.title),
          const SizedBox(height: 4),
          for (final night in season.nights)
            _NightRow(
              first: night.number == 1,
              number: night.number,
              title: night.title,
              date: '${night.hebrewDateLabel}, ${night.day}.${night.month}',
              lit: lit.contains(night.number),
              open: night.hasStarted(now) && !lit.contains(night.number),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LightingScreen(night: night))),
            ),
          const SizedBox(height: 28),
          const Text('תגים', style: AppText.title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final b in Achievement.values)
                _BadgeChip(info: badgeInfo[b]!, earned: score.badges.contains(b)),
            ],
          ),
          const SizedBox(height: 24),
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
        child: Column(
          children: [
            Text(value,
                style: AppText.numeral.copyWith(fontSize: 44, height: 1.1)),
            Text(label, style: AppText.small),
          ],
        ),
      );
}

class _NightRow extends StatelessWidget {
  const _NightRow({
    required this.first,
    required this.number,
    required this.title,
    required this.date,
    required this.lit,
    required this.open,
    required this.onTap,
  });

  final bool first;
  final int number;
  final String title;
  final String date;
  final bool lit;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HairlineRow(
      first: first,
      leading: SizedBox(
        width: 34,
        child: Text(nightLetter(number),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppText.serif,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: lit ? AppColors.brass : AppColors.sill)),
      ),
      title: title,
      subtitle: date,
      trailing: lit
          ? const Icon(Icons.check_circle, color: AppColors.olive)
          : open
              ? const Icon(Icons.chevron_left, color: AppColors.mist)
              : const SizedBox.shrink(),
      onTap: open ? onTap : null,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.info, required this.earned});
  final BadgeInfo info;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: info.howTo,
      triggerMode: TooltipTriggerMode.tap,
      child: earned
          ? OlivePill(emoji: info.emoji, text: info.title)
          : Opacity(
              opacity: .45,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x38F3E9D7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info.emoji),
                    const SizedBox(width: 10),
                    Text(info.title, style: AppText.body.copyWith(fontSize: 15)),
                  ],
                ),
              ),
            ),
    );
  }
}
