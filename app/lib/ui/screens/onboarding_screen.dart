import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/place.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';

/// Three screens, about 30 seconds (Vision, 28.2 to 28.4).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;

  AddressForm _form = AddressForm.plural;
  Place _place = Cities.telAviv;
  bool _locating = false;
  ReminderMode _mode = ReminderMode.sunset;
  TimeOfDay _fixed = const TimeOfDay(hour: 18, minute: 0);
  bool _second = true;
  Nusach _nusach = Nusach.unknown;
  HouseholdMode _household = HouseholdMode.everyone;
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    _pages.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) showSnack(context, 'בלי מיקום זה בסדר, בוחרים עיר מהרשימה');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      setState(() {
        _place = Place(
          id: 'gps',
          name: 'המיקום שלי',
          lat: double.parse(pos.latitude.toStringAsFixed(2)),
          lng: double.parse(pos.longitude.toStringAsFixed(2)),
          timeZone: tzInfo,
        );
      });
    } catch (_) {
      if (mounted) showSnack(context, 'לא הצלחנו למצוא מיקום. בוחרים עיר?');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final profile = UserProfile(
      displayName: _name.text.trim(),
      addressForm: _form,
      nusach: _nusach,
      householdMode: _household,
      place: _place,
      reminders: ReminderSettings(
        mode: _mode,
        fixedHour: _fixed.hour,
        fixedMinute: _fixed.minute,
        secondReminder: _second,
      ),
    );
    final actions = ref.read(appActionsProvider);
    await actions.requestNotifications();
    await ref.read(profileProvider.notifier).save(profile);
    await ref.read(localStoreProvider).logEvent('onboarding_done', {
      'reminder_mode': _mode.name,
      'nusach': _nusach.name,
    });
    try {
      await ref.read(socialProvider).ensureUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _page ? AppColors.brass : AppColors.glass,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [_namePage(), _placePage(), _remindersPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page0Title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(text,
            style: AppText.display),
      );

  Widget _namePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Menorah(shamashLit: true, height: 150, glow: .6),
        const SizedBox(height: 12),
        _page0Title('נעים מאוד.\nאיך לקרוא לך?'),
        TextField(
          controller: _name,
          maxLength: 20,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: 'השם שלך'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const Text('איך לפנות אליך?', style: TextStyle(color: AppColors.mist)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (form, label) in [
              (AddressForm.male, 'אתה'),
              (AddressForm.female, 'את'),
              (AddressForm.plural, 'אתם'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _form == form,
                onSelected: (_) => setState(() => _form = form),
              ),
          ],
        ),
        const SizedBox(height: 40),
        BrassButton(
          label: 'יאללה',
          onPressed: _name.text.trim().isEmpty ? null : _next,
        ),
      ],
    );
  }

  Widget _placePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _page0Title('איפה מדליקים?'),
        const Text(
          'רק בשביל לדעת מתי שקיעה אצלך. המיקום לא יוצא מהטלפון.',
          style: TextStyle(color: AppColors.mist),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useLocation,
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(_place.id == 'gps'
              ? 'המיקום שלי ✓'
              : 'השתמש במיקום שלי'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final city in Cities.all)
              ChoiceChip(
                label: Text(city.name),
                selected: _place.id == city.id,
                onSelected: (_) => setState(() => _place = city),
              ),
          ],
        ),
        const SizedBox(height: 32),
        BrassButton(label: 'הבא', onPressed: _next),
      ],
    );
  }

  Widget _remindersPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _page0Title('מתי להזכיר?'),
        for (final (mode, label, sub) in [
          (ReminderMode.sunset, 'בשקיעה', 'הכי מקובל'),
          (ReminderMode.tzeit, 'בצאת הכוכבים', 'כחצי שעה אחרי השקיעה'),
          (ReminderMode.fixed, 'בשעה קבועה', 'למשל כשחוזרים הביתה'),
        ])
          RadioListTile<ReminderMode>(
            value: mode,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            title: Text(label),
            subtitle: Text(sub, style: const TextStyle(color: AppColors.mist)),
            contentPadding: EdgeInsets.zero,
          ),
        if (_mode == ReminderMode.fixed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () async {
                final t = await showTimePicker(
                    context: context, initialTime: _fixed);
                if (t != null) setState(() => _fixed = t);
              },
              child: Text('שעה: ${_fixed.format(context)}'),
            ),
          ),
        SwitchListTile(
          value: _second,
          onChanged: (v) => setState(() => _second = v),
          title: const Text('תזכורת שנייה אם עוד לא הדלקתי'),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 32),
        const Text('נוסח הברכות', style: TextStyle(color: AppColors.mist)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (n, label) in [
              (Nusach.sefard, 'ספרד / עדות המזרח'),
              (Nusach.ashkenaz, 'אשכנז'),
              (Nusach.unknown, 'לא יודע'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _nusach == n,
                onSelected: (_) => setState(() => _nusach = n),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('אצלנו בבית', style: TextStyle(color: AppColors.mist)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (h, label) in [
              (HouseholdMode.everyone, 'כל אחד מדליק'),
              (HouseholdMode.oneForAll, 'מדליקים אחד בשביל כולם'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _household == h,
                onSelected: (_) => setState(() => _household = h),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('בשבת אנחנו שותקים. ככה צריך 🕯️',
            style: TextStyle(color: AppColors.mist)),
        const SizedBox(height: 24),
        BrassButton(label: 'סיימנו', onPressed: _saving ? null : _finish),
      ],
    );
  }
}
