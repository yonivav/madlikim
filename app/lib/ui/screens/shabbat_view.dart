import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/my_neri.dart';
import '../widgets/neri.dart';
import '../widgets/scene.dart';

/// Vision 28.14: no buttons, no counters. Neri sleeps, "שבת שלום".
class ShabbatView extends ConsumerWidget {
  const ShabbatView({super.key, this.endsAt});

  final DateTime? endsAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(profileProvider)!.place;
    final season = ref.watch(seasonProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final inHanukkah = !now.isBefore(season.first.dayStart) && now.isBefore(season.end);
    final buddy = ref.watch(myNeriProvider);
    final resting = buddyLine(ref.watch(contentProvider), buddy, 'shabbat');

    return Scaffold(
      backgroundColor: AppColors.night,
      body: NightBackdrop(
        shabbat: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MyNeri(size: 170, mood: NeriMood.sleep),
                const SizedBox(height: 26),
                const Text('שבת שלום',
                    style: TextStyle(
                        fontFamily: AppText.serif,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onNight)),
                const SizedBox(height: 10),
                if (endsAt != null)
                  Text(
                    inHanukkah
                        ? '$resting\nנתראה במוצאי שבת ב־${hhmm(endsAt!, place)}'
                        : 'נתראה במוצאי שבת, ${hhmm(endsAt!, place)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, height: 1.6, color: AppColors.onNightSoft),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
