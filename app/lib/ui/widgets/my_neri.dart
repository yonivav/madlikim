import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'neri.dart';

/// The character the user picked (default: נרי, clean orange).
final myNeriProvider = Provider<NeriCharacter>(
    (ref) => NeriCharacter.byId(ref.watch(profileProvider)?.neriId));

/// Draws the user's own character.
class MyNeri extends ConsumerWidget {
  const MyNeri({
    super.key,
    this.mood = NeriMood.happy,
    this.arms = NeriArms.down,
    this.lit = false,
    this.glow = 1,
    this.size = 180,
    this.animate = true,
    this.semanticLabel,
  });

  final NeriMood mood;
  final NeriArms arms;
  final bool lit;
  final double glow;
  final double size;
  final bool animate;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(myNeriProvider);
    return Neri(
      look: c.look,
      mood: mood,
      arms: arms,
      lit: lit,
      glow: glow,
      size: size,
      animate: animate,
      semanticLabel: semanticLabel ?? c.name,
    );
  }
}

/// A line the character says, in its own grammatical gender, with {buddy}
/// filled with its name. Lines live in messages.json under "neri" (he) and
/// "neriF" (she).
String buddyLine(
  ContentBook content,
  NeriCharacter c,
  String key, {
  AddressForm form = AddressForm.plural,
  Map<String, Object?> vars = const {},
  int? index,
}) {
  final section = c.feminine ? 'neriF' : 'neri';
  return content.text('$section.$key',
      form: form, vars: {'buddy': c.name, ...vars}, index: index);
}

/// Grid of characters to pick from (onboarding and settings).
class NeriPicker extends StatelessWidget {
  const NeriPicker({super.key, required this.selectedId, required this.onPick});
  final String selectedId;
  final ValueChanged<NeriCharacter> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: .78,
      children: [
        for (final c in NeriCharacter.all)
          Semantics(
            button: true,
            selected: c.id == selectedId,
            label: '${c.name}, ${c.line}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onPick(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: c.id == selectedId ? const Color(0xFFFFF0C7) : AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: [
                    if (c.id == selectedId)
                      const BoxShadow(color: AppColors.gold, spreadRadius: 4),
                    ...Ink2.shadow(2, 3),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Neri(
                      look: c.look,
                      size: 58,
                      mood: c.id == selectedId ? NeriMood.excited : NeriMood.happy,
                      animate: c.id == selectedId,
                    ),
                    const SizedBox(height: 4),
                    Text(c.name,
                        style: const TextStyle(
                            fontFamily: AppText.round, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
