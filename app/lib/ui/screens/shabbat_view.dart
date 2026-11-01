import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';

/// Vision 28.14: no buttons, no counters. Just "שבת שלום".
class ShabbatView extends ConsumerWidget {
  const ShabbatView({super.key, this.endsAt});

  final DateTime? endsAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(profileProvider)!.place;
    final season = ref.watch(seasonProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final inHanukkah =
        !now.isBefore(season.first.dayStart) && now.isBefore(season.end);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.25),
            radius: .9,
            colors: [Color(0xFF2A2433), Color(0xFF141628), Color(0xFF090F1F)],
            stops: [0, .5, 1],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShabbatCandles(),
                const SizedBox(height: 28),
                Text('שבת שלום', style: AppText.display.copyWith(fontSize: 48)),
                const SizedBox(height: 12),
                if (endsAt != null)
                  Text(
                    inHanukkah
                        ? 'החנוכייה ממשיכה במוצאי שבת.\nנתראה ב־${hhmm(endsAt!, place)}.'
                        : 'נתראה במוצאי שבת, ${hhmm(endsAt!, place)}.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                        fontSize: 17, color: AppColors.mist, height: 1.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
