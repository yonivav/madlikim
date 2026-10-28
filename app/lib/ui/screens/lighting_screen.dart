import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../content/content.dart';
import '../../core/hanukkah.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import 'celebration_screen.dart';
import 'songs_screen.dart';

/// Vision 28.6: dark, big text, the screen stays on.
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CelebrationScreen(
          night: widget.night, light: light, late: late, badgesBefore: before),
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
    final placed = {for (var i = 0; i < night.number; i++) i};

    final orderKey = night.isFirst ? 'first' : 'weekday';
    final order = ContentBook.fill(content.lightingOrder[orderKey] ?? '',
        {'count': night.number == 1 ? 'נר אחד' : '${night.number} נרות'});

    return Theme(
      data: AppTheme.dark().copyWith(scaffoldBackgroundColor: AppColors.nightDeep),
      child: Scaffold(
        appBar: AppBar(
          title: Text(night.title),
          actions: [UnreviewedMark(reviewed: content.reviewed)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Center(
                      child: Text(night.hebrewDateLabel,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                    const SizedBox(height: 12),
                    if (night.kind == NightKind.erevShabbat) ...[
                      GoldBanner(content.lightingOrder['erevShabbat'] ?? ''),
                      const SizedBox(height: 12),
                    ],
                    if (night.kind == NightKind.motzeiShabbat) ...[
                      GoldBanner(content.lightingOrder['motzeiShabbat'] ?? '',
                          icon: Icons.nightlight_round),
                      const SizedBox(height: 12),
                    ],
                    Menorah(
                      placed: placed,
                      lit: lit ? placed : const {},
                      shamashLit: true,
                      orderLabels: lit ? const {} : Menorah.lightingOrder(night.number),
                      height: 190,
                    ),
                    const SizedBox(height: 8),
                    Text(order,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(
                      night.kind == NightKind.erevShabbat
                          ? 'עדיף להדליק לפני ${hhmm(night.preferredUntil, place)}'
                          : 'מדליקים מ-${hhmm(night.windowStart, place)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('הברכות',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        const Text('תעתיק',
                            style: TextStyle(color: AppColors.muted)),
                        Switch(
                          value: profile.showTransliteration,
                          onChanged: (v) => ref
                              .read(profileProvider.notifier)
                              .save(profile.copyWith(showTransliteration: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final b in content.blessingsForNight(night.number))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SongsScreen())),
                      icon: const Icon(Icons.music_note),
                      label: const Text('אחרי ההדלקה: הנרות הללו, מעוז צור'),
                    ),
                    if (_showSafety) ...[
                      const SizedBox(height: 8),
                      Text(content.safety,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ],
                ),
              ),
              _BottomAction(
                night: night,
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
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blessing.firstNightOnly)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('רק הערב',
                    style: TextStyle(
                        color: AppColors.nightDeep,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          Text(
            blessing.textFor(nusach),
            style: const TextStyle(
              fontFamily: AppTheme.blessingFont,
              fontSize: 26,
              height: 1.7,
              color: AppColors.cream,
            ),
          ),
          if (transliteration) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(blessing.transliteration,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.silver, height: 1.4)),
            ),
          ],
          TextButton(
            onPressed: onToggle,
            child: Text(expanded ? 'סגור' : 'מה זה אומר?'),
          ),
          if (expanded) ...[
            Text(blessing.meaning,
                style: const TextStyle(color: AppColors.silver, height: 1.5)),
            if (blessing.variantNote != null) ...[
              const SizedBox(height: 6),
              Text(blessing.variantNote!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.night,
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

  final HanukkahNight night;
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
      button = FilledButton(
        onPressed: null,
        child: Text(say(form,
            m: 'כבר הדלקת הערב 🕯️',
            f: 'כבר הדלקת הערב 🕯️',
            p: 'כבר הדלקתם הערב 🕯️')),
      );
    } else if (canMarkNow) {
      button = FilledButton(
        onPressed: busy ? null : () => onMark(late: false),
        child: const Text('הדלקתי! 🕯️', style: TextStyle(fontSize: 20)),
      );
    } else if (canMarkLate) {
      button = OutlinedButton(
        onPressed: busy ? null : () => onMark(late: true),
        child: const Text('שכחתי לסמן, הדלקתי'),
      );
    } else {
      button = FilledButton(
        onPressed: null,
        child: Text('עוד מוקדם, מדליקים מ-$startsAt'),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.night,
        border: Border(top: BorderSide(color: AppColors.nightCard)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!lit && (canMarkNow || canMarkLate))
            SwitchListTile(
              value: withGuests,
              onChanged: onGuests,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('הדלקנו עם אורחים 🏠'),
            ),
          button,
        ],
      ),
    );
  }
}
