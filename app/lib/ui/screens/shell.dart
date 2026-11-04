import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_phase.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'my_menorah_screen.dart';
import 'shabbat_view.dart';
import 'songs_screen.dart';

/// Which tab is showing. Home can switch tabs (e.g. "החבר'ה").
final shellTabProvider = StateProvider<int>((_) => 0);

class Shell extends ConsumerWidget {
  const Shell({super.key});

  static const _tabs = [
    ('🏠', 'בית'),
    ('🕎', 'החנוכייה'),
    ('👨‍👩‍👧', 'החבר\'ה'),
    ('🎶', 'שירים'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(phaseProvider);
    if (snap.phase == AppPhase.shabbat) {
      return ShabbatView(endsAt: snap.shabbatEndsAt);
    }
    final index = ref.watch(shellTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          MyMenorahScreen(),
          GroupsScreen(),
          SongsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: GlossBox(
            height: 68,
            decoration: Gloss.pearl(lift: 10),
            shine: .9,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == index,
                      button: true,
                      label: _tabs[i].$2,
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(shellTabProvider.notifier).state = i;
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: i == index ? 1 : .9,
                                child: GlossBox(
                                  width: 38,
                                  height: 38,
                                  decoration: i == index
                                      ? Gloss.honey(shape: BoxShape.circle, lift: 5)
                                      : const BoxDecoration(shape: BoxShape.circle),
                                  shine: i == index ? .6 : 0,
                                  alignment: Alignment.center,
                                  child: Text(_tabs[i].$1, style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tabs[i].$2,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                                  color: i == index ? AppColors.ink : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
