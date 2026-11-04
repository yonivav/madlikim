import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../content/content.dart';
import '../../core/hanukkah.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hanukkiah.dart';
import '../widgets/neri.dart';
import 'celebration_screen.dart';
import 'songs_screen.dart';

/// Vision 28.6: big text, the screen stays on, everything in order.
class LightingScreen extends ConsumerStatefulWidget {
  const LightingScreen({super.key, required this.night});

  final HanukkahNight night;

  @override
  ConsumerState<LightingScreen> createState() => _LightingScreenState();
}

class _LightingScreenState extends ConsumerState<LightingScreen> {
  bool _withGuests = false;
  bool _busy = false;
  final Set<String> _expanded = {};
  late final bool _showSafety;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
    final store = ref.read(localStoreProvider);
    final key = 'safety_${widget.night.hebrewYear}';
    _showSafety = !store.flag(key);
    if (_showSafety) store.setFlag(key);
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  Future<void> _mark({required bool late}) async {
    setState(() => _busy = true);
    final before = ref.read(scoreProvider).badges;
    final light = await ref
        .read(appActionsProvider)
        .markLit(widget.night, withGuests: _withGuests, late: late);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => CelebrationScreen(
          night: widget.night, light: light, late: late, badgesBefore: before),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final night = widget.night;
    final content = ref.watch(contentProvider);
    final profile = ref.watch(profileProvider)!;
    final place = profile.place;
    ref.watch(nowProvider); // re-evaluate the button as time passes
    final lit = ref.watch(litNightsProvider).contains(night.number);
    final actions = ref.read(appActionsProvider);
    final first = night.isFirst;
    final steps = content.steps;
    final count = night.number == 1 ? 'נר אחד' : '${night.number} נרות';
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'סגירה',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(night.isLast ? 'וזאת חנוכה' : night.title),
        actions: [UnreviewedMark(reviewed: content.reviewed)],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    Center(child: Text(night.hebrewDateLabel, style: AppText.small)),
                    if (night.kind == NightKind.erevShabbat)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: GoldBanner(content.lightingOrder['erevShabbat'] ?? ''),
                      ),
                    if (night.kind == NightKind.motzeiShabbat)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: GoldBanner(content.lightingOrder['motzeiShabbat'] ?? '',
                            icon: Icons.nightlight_round),
                      ),
                    const SizedBox(height: 6),
                    Center(
                      child: Hanukkiah(
                        placed: night.number,
                        lit: lit ? {for (var i = 0; i < night.number; i++) i} : const {},
                        showOrder: !lit,
                        width: (width - 28).clamp(0.0, 420.0).toDouble(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        children: [
                          _Step(
                            n: 1,
                            text: ContentBook.fill(
                                (first ? steps['placeFirst'] : steps['place']) ?? '',
                                {'count': count}),
                            bold: count,
                          ),
                          _Step(n: 2, text: (first ? steps['blessFirst'] : steps['bless']) ?? ''),
                          _Step(n: 3, text: (first ? steps['lightFirst'] : steps['light']) ?? ''),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                      child: Text(
                        night.kind == NightKind.erevShabbat
                            ? 'עדיף להדליק לפני ${hhmm(night.preferredUntil, place)}'
                            : 'מדליקים מ־${hhmm(night.windowStart, place)}',
                        style: AppText.small,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          const Expanded(child: Text('הברכות', style: AppText.title)),
                          Text('תעתיק', style: AppText.small),
                          const SizedBox(width: 6),
                          Switch(
                            value: profile.showTransliteration,
                            onChanged: (v) => ref
                                .read(profileProvider.notifier)
                                .save(profile.copyWith(showTransliteration: v)),
                          ),
                        ],
                      ),
                    ),
                    for (final b in content.blessingsForNight(night.number))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                        child: _BlessingCard(
                          blessing: b,
                          nusach: profile.nusach,
                          transliteration: profile.showTransliteration,
                          expanded: _expanded.contains(b.id),
                          onToggle: () => setState(() => _expanded.contains(b.id)
                              ? _expanded.remove(b.id)
                              : _expanded.add(b.id)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: HairlineRow(
                        title: 'אחרי ההדלקה',
                        subtitle: 'הנרות הללו, מעוז צור עם אקורדים',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SongsScreen())),
                      ),
                    ),
                    if (_showSafety)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                        child: Text(content.safety,
                            textAlign: TextAlign.center, style: AppText.small),
                      ),
                  ],
                ),
                // Neri peeks in from the corner to keep you company.
                PositionedDirectional(
                  end: -16,
                  bottom: -12,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -.18,
                      child: const Neri(
                        size: 84,
                        mood: NeriMood.happy,
                        arms: NeriArms.wave,
                        semanticLabel: 'נרי',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Dock(
            lit: lit,
            canMarkNow: actions.canMarkNow(night),
            canMarkLate: actions.canMarkLate(night),
            busy: _busy,
            withGuests: _withGuests,
            onGuests: (v) => setState(() => _withGuests = v),
            onMark: _mark,
            form: profile.addressForm,
            startsAt: hhmm(night.windowStart, place),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text, this.bold});
  final int n;
  final String text;
  final String? bold;

  @override
  Widget build(BuildContext context) {
    final i = bold == null ? -1 : text.indexOf(bold!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text('$n',
                style: const TextStyle(
                    fontFamily: AppText.round,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: i < 0
                ? Text(text, style: AppText.body)
                : Text.rich(TextSpan(style: AppText.body, children: [
                    TextSpan(text: text.substring(0, i)),
                    TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: text.substring(i + bold!.length)),
                  ])),
          ),
        ],
      ),
    );
  }
}

class _BlessingCard extends StatelessWidget {
  const _BlessingCard({
    required this.blessing,
    required this.nusach,
    required this.transliteration,
    required this.expanded,
    required this.onToggle,
  });

  final Blessing blessing;
  final Nusach nusach;
  final bool transliteration;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blessing.firstNightOnly)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: const Text('רק הערב',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          Text(blessing.textFor(nusach), style: AppText.prayer),
          if (transliteration) ...[
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(blessing.transliteration, style: AppText.small.copyWith(fontSize: 15)),
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(blessing.meaning, style: AppText.body.copyWith(color: AppColors.muted)),
                        if (blessing.variantNote != null) ...[
                          const SizedBox(height: 6),
                          Text(blessing.variantNote!, style: AppText.small.copyWith(fontSize: 13)),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(expanded ? 'סגירה' : 'מה זה אומר?'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.lit,
    required this.canMarkNow,
    required this.canMarkLate,
    required this.busy,
    required this.withGuests,
    required this.onGuests,
    required this.onMark,
    required this.form,
    required this.startsAt,
  });

  final bool lit;
  final bool canMarkNow;
  final bool canMarkLate;
  final bool busy;
  final bool withGuests;
  final ValueChanged<bool> onGuests;
  final Future<void> Function({required bool late}) onMark;
  final AddressForm form;
  final String startsAt;

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (lit) {
      button = BrassButton(
        label: say(form,
            m: 'כבר הדלקת הערב', f: 'כבר הדלקת הערב', p: 'כבר הדלקתם הערב'),
        emoji: '🕯️',
        onPressed: null,
      );
    } else if (canMarkNow) {
      button = BrassButton(
        label: 'הדלקתי',
        emoji: '🔥',
        onPressed: busy ? null : () => onMark(late: false),
      );
    } else if (canMarkLate) {
      button = BrassButton(
        label: 'שכחתי לסמן, הדלקתי',
        ghost: true,
        onPressed: busy ? null : () => onMark(late: true),
      );
    } else {
      button = BrassButton(label: 'עוד מוקדם, מדליקים מ־$startsAt', onPressed: null);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(22, 8, 22, 14 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!lit && (canMarkNow || canMarkLate))
            Row(
              children: [
                Expanded(child: Text('הדלקנו עם אורחים 🏠', style: AppText.body.copyWith(fontSize: 15))),
                Switch(value: withGuests, onChanged: onGuests),
              ],
            ),
          button,
        ],
      ),
    );
  }
}
