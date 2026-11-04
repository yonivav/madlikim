import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../core/hebrew_numerals.dart';
import '../../social/social_models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

String inviteLink(String appLink, String id) => '$appLink/i/$id';

final inviteProvider = StreamProvider.family<HostInvite?, String>(
    (ref, id) => ref.watch(socialProvider).watchInvite(id));

Future<void> shareInvite(WidgetRef ref, HostInvite invite) {
  final content = ref.read(contentProvider);
  ref.read(localStoreProvider).logEvent('share_tapped', {'kind': 'invite'});
  return shareText(content
      .text('share.invite', vars: {
        'title': 'נר ${ordinalsMasculine[invite.night]}',
        'time': invite.time,
        'note': invite.note,
        'link': inviteLink(content.appLink, invite.id),
      })
      .replaceAll('\n\n', '\n'));
}

/// Vision 28.11: night, time, a note. No address field (decision #6).
class InviteCreateScreen extends ConsumerStatefulWidget {
  const InviteCreateScreen({super.key});

  @override
  ConsumerState<InviteCreateScreen> createState() => _InviteCreateScreenState();
}

class _InviteCreateScreenState extends ConsumerState<InviteCreateScreen> {
  int? _night;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 30);
  final _note = TextEditingController(text: 'יש סופגניות 🍩');
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final night = _night;
    if (night == null) return;
    final myName = await ensureDisplayName(context, ref);
    if (myName == null) return;
    setState(() => _busy = true);
    final season = ref.read(seasonProvider);
    final time =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    try {
      final invite = await ref.read(socialProvider).createInvite(
            hebrewYear: season.hebrewYear,
            night: night,
            time: time,
            note: _note.text.trim(),
            myName: myName,
          );
      await ref
          .read(localStoreProvider)
          .logEvent('invite_created', {'night': night});
      await shareInvite(ref, invite);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => InviteScreen(inviteId: invite.id)));
    } catch (_) {
      if (mounted) showSnack(context, 'משהו השתבש. ננסה שוב?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(seasonProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
    final upcoming =
        season.nights.where((n) => now.isBefore(n.windowEnd)).toList();
    final selected = _night == null ? null : season.night(_night!);

    return Scaffold(
      appBar: AppBar(title: const Text('בואו להדליק אצלי')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('באיזה ערב?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const Text('חנוכה השנה כבר נגמר. נתראה בשנה הבאה 🕎',
                style: TextStyle(color: AppColors.muted)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in upcoming)
                ChoiceChip(
                  label: Text(
                      '${n.title} · ${weekdayNames[n.weekday]} ${n.day}.${n.month}'),
                  selected: _night == n.number,
                  onSelected: (_) => setState(() => _night = n.number),
                ),
            ],
          ),
          if (selected != null && selected.kind == NightKind.erevShabbat) ...[
            const SizedBox(height: 12),
            const GoldBanner(
                'ערב שבת: מדליקים לפני כניסת שבת. כדאי שהאורחים יגיעו מוקדם.'),
          ],
          const SizedBox(height: 20),
          const Text('באיזו שעה?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final t =
                  await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            child: Text(_time.format(context)),
          ),
          const SizedBox(height: 20),
          const Text('משהו להוסיף?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(controller: _note, maxLength: 120, maxLines: 2),
          const SizedBox(height: 4),
          const Text(
            'את הכתובת שולחים בוואטסאפ. אנחנו לא שומרים כתובות.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _night == null || _busy ? null : _create,
            icon: const Icon(Icons.send),
            label: const Text('ליצור ולשלוח'),
          ),
        ],
      ),
    );
  }
}

class InvitesListScreen extends ConsumerWidget {
  const InvitesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(myInvitesProvider).valueOrNull ?? const [];
    final me = ref.watch(socialProvider).currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('ערבי הדלקה')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final i in invites) ...[
            SectionCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InviteScreen(inviteId: i.id))),
              child: Row(
                children: [
                  Text(i.hostId == me ? '🏠' : '🎟️',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            i.hostId == me
                                ? 'אצלי · נר ${ordinalsMasculine[i.night]}'
                                : 'אצל ${i.hostName} · נר ${ordinalsMasculine[i.night]}',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text('${i.time} · ${i.count(RsvpStatus.yes)} מגיעים',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InviteCreateScreen())),
            icon: const Icon(Icons.add),
            label: const Text('הזמנה חדשה'),
          ),
        ],
      ),
    );
  }
}

class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.inviteId});

  final String inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialProvider);
    final me = social.currentUserId;
    return ref.watch(inviteProvider(inviteId)).when(
          loading: () => Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator())),
          error: (_, __) => Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('לא הצלחנו לטעון את ההזמנה'))),
          data: (invite) {
            if (invite == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(
                    child: Text('ההזמנה הזו כבר לא קיימת',
                        style: TextStyle(color: AppColors.muted))),
              );
            }
            final mine = invite.hostId == me;
            final myStatus = me == null ? null : invite.rsvps[me]?.status;
            return Scaffold(
              appBar: AppBar(
                title: Text(mine ? 'ההזמנה שלי' : 'הזמנה מ${invite.hostName}'),
                actions: [
                  if (mine)
                    IconButton(
                      tooltip: 'מחיקה',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await social.deleteInvite(invite.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Center(
                      child: Text('🕎', style: TextStyle(fontSize: 56))),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'נר ${ordinalsMasculine[invite.night]} · ${invite.time}',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (invite.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(invite.note,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 17, color: AppColors.muted)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!mine) ...[
                    const Text('מגיעים?',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final (s, label) in [
                          (RsvpStatus.yes, 'מגיע/ה 🙌'),
                          (RsvpStatus.maybe, 'אולי'),
                          (RsvpStatus.no, 'לא הפעם'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: myStatus == s,
                            onSelected: (_) async {
                              final myName = await ensureDisplayName(context, ref);
                              if (myName == null) return;
                              await social.rsvp(
                                inviteId: invite.id,
                                status: s,
                                myName: myName,
                              );
                              await ref
                                  .read(localStoreProvider)
                                  .logEvent('rsvp', {'status': s.name});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                      '${invite.count(RsvpStatus.yes)} מגיעים · ${invite.count(RsvpStatus.maybe)} אולי',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final e in invite.rsvps.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.value.name),
                      trailing: Text(switch (e.value.status) {
                        RsvpStatus.yes => '🙌',
                        RsvpStatus.maybe => '🤔',
                        RsvpStatus.no => '🙅',
                      }),
                    ),
                  if (mine) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => shareInvite(ref, invite),
                      icon: const Icon(Icons.share),
                      label: const Text('לשלוח שוב'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }
}
