import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hebrew_numerals.dart';
import '../../logic/scoring.dart';
import '../../social/social_models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/avatars.dart';
import '../widgets/common.dart';

/// The night the social screens talk about: tonight, or the latest one that
/// started, or night 1 before Hanukkah.
final socialNightProvider = Provider<int>((ref) {
  final snap = ref.watch(phaseProvider);
  if (snap.night != null) return snap.night!.number;
  final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now().toUtc();
  final started = snap.season.nights.where((n) => n.hasStarted(now));
  return started.isEmpty ? 1 : started.last.number;
});

final groupNightProvider =
    StreamProvider.family<GroupNight, (String, int)>((ref, key) =>
        ref.watch(socialProvider).watchGroupNight(key.$1, key.$2));

String groupLink(String appLink, String code) => '$appLink/j/$code';

Future<void> shareGroup(WidgetRef ref, Group g) {
  final content = ref.read(contentProvider);
  ref.read(localStoreProvider).logEvent('share_tapped', {'kind': 'group'});
  return shareText(content.text('share.group', vars: {
    'group': g.name,
    'code': g.inviteCode,
    'link': groupLink(content.appLink, g.inviteCode),
  }));
}

/// Vision 28.9
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    final social = ref.watch(socialProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('חנוכיות משותפות')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!social.isRemote) ...[
            const GoldBanner(
              'מצב מקומי: השרת עוד לא מחובר, אז חנוכייה משותפת כוללת רק את מי שבמכשיר הזה. הכל יעבוד אחרי חיבור Firebase.',
              icon: Icons.cloud_off,
            ),
            const SizedBox(height: 16),
          ],
          ...groups.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (e, _) => [
              const Text('אין חיבור, נעדכן את החבר\'ה אחר כך.',
                  style: TextStyle(color: AppColors.muted)),
            ],
            data: (list) => [
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'עוד אין חנוכיות משותפות.\nפותחים אחת ושולחים קישור בוואטסאפ למשפחה או לחבר\'ה.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ),
              for (final g in list) ...[
                SectionCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GroupScreen(groupId: g.id))),
                  child: Row(
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            Text('${g.members.length} חברים · ${g.totalLight} אור',
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
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('חנוכייה חדשה'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JoinGroupScreen())),
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('יש לי קוד'),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (_) => const _CreateGroupSheet(),
    );
    if (result == null) return;
    final profile = ref.read(profileProvider)!;
    final season = ref.read(seasonProvider);
    try {
      final g = await ref.read(socialProvider).createGroup(
            name: result.$1,
            emoji: result.$2,
            hebrewYear: season.hebrewYear,
            myName: profile.displayName,
          );
      await ref.read(localStoreProvider).logEvent('group_created');
      // Count lightings already done this year.
      for (final r in ref.read(seasonLightingsProvider)) {
        await ref.read(socialProvider).recordLighting(
            hebrewYear: r.hebrewYear,
            night: r.night,
            light: Scoring.lightFor(r));
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id)));
    } catch (_) {
      if (context.mounted) showSnack(context, 'משהו השתבש. ננסה שוב?');
    }
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _name = TextEditingController();
  String _emoji = '🕎';
  static const _emojis = ['🕎', '👨‍👩‍👧‍👦', '🍩', '🏠', '🪖', '🎓', '🌟', '❤️'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('חנוכייה חדשה',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(
                hintText: 'למשל: משפחת כהן, החבר\'ה מהצבא'),
            onChanged: (_) => setState(() {}),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final e in _emojis)
                ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 20)),
                  selected: _emoji == e,
                  onSelected: (_) => setState(() => _emoji = e),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop((_name.text.trim(), _emoji)),
            child: const Text('לפתוח'),
          ),
        ],
      ),
    );
  }
}

/// Vision 28.10
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(socialNightProvider);
    final social = ref.watch(socialProvider);
    final me = social.currentUserId;
    final isShabbat = ref.watch(isShabbatProvider);

    return ref.watch(groupNightProvider((groupId, night))).when(
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(
            child: Text('לא הצלחנו לטעון. אולי החנוכייה נמחקה?')),
      ),
      loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator())),
      data: (data) {
        final g = data.group;
        final litCount = data.litMemberIds.length;
        return Scaffold(
          appBar: AppBar(
            title: Text('${g.emoji} ${g.name}'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    final name = await _askName(context, g.name);
                    if (name != null) await social.renameGroup(g.id, name);
                  } else if (v == 'leave') {
                    await social.leaveGroup(g.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                itemBuilder: (_) => [
                  if (g.ownerId == me)
                    const PopupMenuItem(value: 'rename', child: Text('שינוי שם')),
                  PopupMenuItem(
                      value: 'leave',
                      child: Text(g.ownerId == me ? 'מחיקת החנוכייה' : 'יציאה')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Text('${g.totalLight}', style: AppText.numeral),
                    Text('אור ביחד', style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (data.nudgesToMe.isNotEmpty) ...[
                GoldBanner(
                    '${data.nudgesToMe.join(', ')} שלחו לך אור 🕯️',
                    icon: Icons.favorite),
                const SizedBox(height: 16),
              ],
              Text('נר ${ordinalsMasculine[night]}: $litCount מתוך ${g.members.length} הדליקו',
                  style: AppText.heading),
              const SizedBox(height: 8),
              for (final m in g.members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(
                      member: m, lit: data.litMemberIds.contains(m.id), size: 38),
                  title: Text(m.id == me ? '${m.name} (אני)' : m.name),
                  trailing: data.litMemberIds.contains(m.id)
                      ? const Icon(Icons.check_circle, color: AppColors.olive)
                      : (m.id == me || isShabbat)
                          ? null
                          : data.nudgedByMe.contains(m.id)
                              ? const Text('נשלח ✓',
                                  style: TextStyle(color: AppColors.muted))
                              : TextButton(
                                  onPressed: () async {
                                    await social.sendNudge(
                                      groupId: g.id,
                                      toUserId: m.id,
                                      night: night,
                                      myName: ref
                                          .read(profileProvider)!
                                          .displayName,
                                    );
                                    await ref
                                        .read(localStoreProvider)
                                        .logEvent('nudge_sent');
                                  },
                                  child: const Text('שלח אור'),
                                ),
                ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('קוד להצטרפות',
                        style: TextStyle(color: AppColors.muted)),
                    SelectableText(g.inviteCode,
                        style: const TextStyle(
                            fontSize: 32,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BrassButton(
                label: 'להזמין עוד',
                icon: Icons.ios_share,
                onPressed: () => shareGroup(ref, g),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askName(BuildContext context, String current) {
    final c = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('שם חדש'),
        content: TextField(controller: c, autofocus: true, maxLength: 30),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('שמירה')),
        ],
      ),
    );
  }
}

/// Join with a code, from a link or typed by hand.
class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key, this.initialCode, this.fromLink = false});

  final String? initialCode;
  final bool fromLink;

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final profile = ref.read(profileProvider)!;
    try {
      final g = await ref
          .read(socialProvider)
          .joinByCode(_code.text, myName: profile.displayName);
      if (g == null) {
        setState(() => _error = 'לא מצאנו חנוכייה כזו. אולי הקוד השתבש?');
        return;
      }
      if (g.hebrewYear != ref.read(seasonProvider).hebrewYear) {
        setState(() => _error =
            'החנוכייה הזו משנה אחרת. אפשר לפתוח חדשה ולהזמין את אותם אנשים.');
        return;
      }
      await ref.read(localStoreProvider).logEvent(
          'group_joined', {'source': widget.fromLink ? 'link' : 'code'});
      for (final r in ref.read(seasonLightingsProvider)) {
        await ref.read(socialProvider).recordLighting(
            hebrewYear: r.hebrewYear,
            night: r.night,
            light: Scoring.lightFor(r));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id)));
    } catch (_) {
      setState(() => _error = 'אין חיבור כרגע. ננסה שוב עוד רגע?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הצטרפות לחנוכייה')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('הקוד שקיבלת (6 תווים)',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLength: 7,
            style: const TextStyle(
                fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.flame)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ||
                    !InviteCodes.isValid(InviteCodes.normalize(_code.text))
                ? null
                : _join,
            child: const Text('אני בפנים'),
          ),
        ],
      ),
    );
  }
}
