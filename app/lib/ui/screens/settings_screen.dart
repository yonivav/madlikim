import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/place.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/my_neri.dart';
import '../widgets/neri.dart';

/// Vision 28.13
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const Scaffold();
    final content = ref.watch(contentProvider);
    final social = ref.watch(socialProvider);
    final save = ref.read(profileProvider.notifier).save;
    final r = profile.reminders;

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.w800)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          header('עליי'),
          Builder(builder: (context) {
            final buddy = NeriCharacter.byId(profile.neriId);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Neri(look: buddy.look, size: 34, animate: false),
              title: const Text('הנר שלי'),
              subtitle: Text('${buddy.name}, ${buddy.line}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (sheet) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('בחרו את הנר שלכם', style: AppText.title),
                      const SizedBox(height: 14),
                      NeriPicker(
                        selectedId: profile.neriId,
                        onPick: (c) {
                          save(profile.copyWith(neriId: c.id));
                          Navigator.pop(sheet);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('שם'),
            subtitle: Text(profile.displayName.isEmpty
                ? 'לא הוגדר, נדרש כדי לשתף'
                : profile.displayName),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final name = await _askText(context, 'איך לקרוא לך?',
                  profile.displayName);
              if (name != null && name.isNotEmpty) {
                await save(profile.copyWith(displayName: name));
              }
            },
          ),
          _Choice<AddressForm>(
            label: 'פנייה',
            value: profile.addressForm,
            options: const {
              AddressForm.male: 'אתה',
              AddressForm.female: 'את',
              AddressForm.plural: 'אתם',
            },
            onChanged: (v) => save(profile.copyWith(addressForm: v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('עיר'),
            subtitle: Text(profile.place.name),
            trailing: const Icon(Icons.place_outlined),
            onTap: () async {
              final place = await showModalBottomSheet<Place>(
                context: context,
                backgroundColor: AppColors.paper,
                builder: (sheet) => ListView(
                  children: [
                    for (final c in Cities.all)
                      ListTile(
                        title: Text(c.name),
                        trailing: c.id == profile.place.id
                            ? const Icon(Icons.check, color: AppColors.orange)
                            : null,
                        onTap: () => Navigator.pop(sheet, c),
                      ),
                  ],
                ),
              );
              if (place != null) await save(profile.copyWith(place: place));
            },
          ),
          _Choice<Nusach>(
            label: 'נוסח',
            value: profile.nusach,
            options: const {
              Nusach.sefard: 'ספרד',
              Nusach.ashkenaz: 'אשכנז',
              Nusach.unknown: 'לא יודע',
            },
            onChanged: (v) => save(profile.copyWith(nusach: v)),
          ),
          _Choice<HouseholdMode>(
            label: 'מי מדליק',
            value: profile.householdMode,
            options: const {
              HouseholdMode.everyone: 'כל אחד',
              HouseholdMode.oneForAll: 'אחד בשביל כולם',
            },
            onChanged: (v) => save(profile.copyWith(householdMode: v)),
          ),
          header('תזכורות'),
          _Choice<ReminderMode>(
            label: 'מתי',
            value: r.mode,
            options: const {
              ReminderMode.sunset: 'שקיעה',
              ReminderMode.tzeit: 'צאת הכוכבים',
              ReminderMode.fixed: 'שעה קבועה',
            },
            onChanged: (v) =>
                save(profile.copyWith(reminders: r.copyWith(mode: v))),
          ),
          if (r.mode == ReminderMode.fixed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('שעה'),
              trailing: Text(
                  '${r.fixedHour.toString().padLeft(2, '0')}:${r.fixedMinute.toString().padLeft(2, '0')}'),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: r.fixedHour, minute: r.fixedMinute),
                );
                if (t != null) {
                  await save(profile.copyWith(
                      reminders:
                          r.copyWith(fixedHour: t.hour, fixedMinute: t.minute)));
                }
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('תזכורת שנייה אם עוד לא הדלקתי'),
            value: r.secondReminder,
            onChanged: (v) => save(
                profile.copyWith(reminders: r.copyWith(secondReminder: v))),
          ),
          const Text(
            'בערב שבת התזכורת מגיעה לפי כניסת שבת, ובשבת עצמה אין התראות בכלל.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('בדיקת התראות'),
            onPressed: () async {
              await ref.read(appActionsProvider).requestNotifications();
              await ref.read(notificationServiceProvider).showNow(
                    content.text('notifications.test.title'),
                    content.text('notifications.test.body'),
                  );
            },
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('ההתראות לא מגיעות?'),
                content: const Text(
                  'בחלק מהטלפונים (במיוחד שיאומי וסמסונג) מצב חיסכון בסוללה עוצר התראות.\n\n'
                  'בהגדרות הטלפון: אפליקציות ← מדליקים ← סוללה ← "ללא הגבלה".\n'
                  'ובאייפון: הגדרות ← עדכונים ← מדליקים ← לאפשר עדכונים.',
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('הבנתי')),
                ],
              ),
            ),
            child: const Text('איך לוודא שההתראות מגיעות'),
          ),
          header('אודות'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('בדיקת תוכן'),
            subtitle: Text(content.reviewed
                ? 'כל התוכן נבדק על ידי רב'
                : 'התוכן ההלכתי עדיין בבדיקה'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('שכבה חברתית'),
            subtitle: Text(social.isRemote
                ? 'מחובר'
                : 'מצב מקומי (השרת עוד לא מוגדר)'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.flame,
                side: const BorderSide(color: AppColors.flame)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('למחוק הכל?'),
                  content: const Text(
                      'נמחק את השם, ההדלקות וההגדרות מהטלפון, ונצא מכל החנוכיות המשותפות. אי אפשר לבטל.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('ביטול')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('למחוק')),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(appActionsProvider).deleteEverything();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            child: const Text('מחק את כל המידע שלי'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<String?> _askText(BuildContext context, String title, String current) {
    final c = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, maxLength: 20),
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

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  onSelected: (_) => onChanged(e.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
