import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Vision 28.14: no buttons, no counters. Just "שבת שלום".
class ShabbatView extends ConsumerWidget {
  const ShabbatView({super.key, this.endsAt});

  final DateTime? endsAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(profileProvider)!.place;
    final season = ref.watch(seasonProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final inHanukkah = !now.isBefore(season.first.dayStart) &&
        now.isBefore(season.end);

    return Scaffold(
      backgroundColor: AppColors.nightDeep,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🕯️ 🕯️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 24),
                const Text('שבת שלום',
                    style:
                        TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (endsAt != null)
                  Text(
                    inHanukkah
                        ? 'החנוכייה ממשיכה במוצאי שבת. נתראה ב-${hhmm(endsAt!, place)}.'
                        : 'נתראה במוצאי שבת, ${hhmm(endsAt!, place)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, color: AppColors.silver, height: 1.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
