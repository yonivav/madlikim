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
        padding: const EdgeInsets.all(20),
        children: [
          Menorah(
            placed: positions,
            lit: positions,
            shamashLit: positions.isNotEmpty,
            height: 220,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'אור', value: '${score.light}'),
              _Stat(label: 'לילות', value: '${score.nightsLit}/8'),
              _Stat(label: 'ברצף', value: '${score.currentStreak}'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('הלילות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final night in season.nights)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(lit.contains(night.number) ? '🕯️' : '·',
                  style: const TextStyle(fontSize: 22)),
              title: Text(night.title),
              subtitle: Text(
                  '${night.hebrewDateLabel} · ${night.day}.${night.month}',
                  style: const TextStyle(color: AppColors.muted)),
              trailing: lit.contains(night.number)
                  ? const Icon(Icons.check_circle, color: AppColors.gold)
                  : night.hasStarted(now)
                      ? const Icon(Icons.chevron_left)
                      : null,
              onTap: night.hasStarted(now) && !lit.contains(night.number)
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LightingScreen(night: night)))
                  : null,
            ),
          const SizedBox(height: 24),
          const Text('תגים',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in Achievement.values)
                Tooltip(
                  message: badgeInfo[b]!.howTo,
                  child: Opacity(
                    opacity: score.badges.contains(b) ? 1 : 0.35,
                    child: Chip(
                      avatar: Text(badgeInfo[b]!.emoji),
                      label: Text(badgeInfo[b]!.title),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('לחיצה ארוכה על תג מראה איך משיגים אותו',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 24),
          SectionCard(
            child: Text(
              'מקסימום לבד: ${HanukkahSeason.maxLight} אור (1+2+...+8). אורחים וחברים שמצטרפים מוסיפים עוד.',
              style: const TextStyle(color: AppColors.silver),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold)),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
