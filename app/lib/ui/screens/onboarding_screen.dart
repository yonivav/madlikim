import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/place.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/my_neri.dart';
import '../widgets/neri.dart';
import '../widgets/scene.dart';

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
  String _neriId = 'neri';

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
      neriId: _neriId,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      width: i == _page ? 28 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: i <= _page
                          ? Gloss.candy()
                          : BoxDecoration(
                              color: AppColors.paper2,
                              borderRadius: BorderRadius.circular(999),
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
                children: [_pickPage(), _namePage(), _placePage(), _remindersPage()],
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

  NeriCharacter get _buddy => NeriCharacter.byId(_neriId);

  /// First thing: pick your candle.
  Widget _pickPage() {
    final content = ref.watch(contentProvider);
    final c = _buddy;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('בחרו את הנר שלכם', textAlign: TextAlign.center, style: AppText.display),
        const SizedBox(height: 4),
        Text('הוא יזכיר לכם להדליק, ויחגוג איתכם כל ערב',
            textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 14.5)),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SpeechBubble(buddyLine(content, c, 'picked')),
        ),
        SizedBox(
          height: 210,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween(begin: .85, end: 1.0)
                      .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                  child: FadeTransition(opacity: a, child: child)),
              child: Neri(
                key: ValueKey(c.id),
                look: c.look,
                size: 128,
                mood: NeriMood.excited,
                arms: NeriArms.wave,
                semanticLabel: '${c.name}, ${c.line}',
              ),
            ),
          ),
        ),
        Text(c.line, textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 14)),
        const SizedBox(height: 14),
        NeriPicker(
          selectedId: _neriId,
          onPick: (picked) => setState(() => _neriId = picked.id),
        ),
        const SizedBox(height: 22),
        BrassButton(
            label: '${c.name} ${c.feminine ? 'היא' : 'הוא'} הנר שלי!', onPressed: _next),
      ],
    );
  }

  Widget _namePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Positioned(right: 0, bottom: 0, child: OliveBranch(size: 100)),
              Neri(
                look: _buddy.look,
                size: 120,
                arms: NeriArms.wave,
                semanticLabel: _buddy.name,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('אני אזכיר לך להדליק כל ערב בחנוכה, ונדליק ביחד.',
            textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 15)),
        const SizedBox(height: 20),
        _page0Title('איך לקרוא לך?'),
        TextField(
          controller: _name,
          maxLength: 20,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: 'השם שלך'),
        ),
        const SizedBox(height: 4),
        const Text(
            'אפשר גם בלי. רק אם תרצו להזמין חברים או לשתף חנוכייה, נבקש שם אז.',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('איך לפנות אליך?', style: TextStyle(color: AppColors.muted)),
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
        BrassButton(label: 'יאללה', onPressed: _next),
      ],
    );
  }

  Widget _placePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: Neri(look: _buddy.look, size: 90, mood: NeriMood.calm, animate: false)),
        _page0Title('איפה מדליקים?'),
        const Text(
          'רק בשביל לדעת מתי שקיעה אצלך. המיקום לא יוצא מהטלפון.',
          style: TextStyle(color: AppColors.muted),
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
        Center(child: Neri(look: _buddy.look, size: 90, arms: NeriArms.up, animate: false)),
        _page0Title('מתי להזכיר?'),
        RadioGroup<ReminderMode>(
          groupValue: _mode,
          onChanged: (v) => setState(() => _mode = v ?? _mode),
          child: Column(
            children: [
              for (final (mode, label, sub) in [
                (ReminderMode.sunset, 'בשקיעה', 'הכי מקובל'),
                (ReminderMode.tzeit, 'בצאת הכוכבים', 'כחצי שעה אחרי השקיעה'),
                (ReminderMode.fixed, 'בשעה קבועה', 'למשל כשחוזרים הביתה'),
              ])
                RadioListTile<ReminderMode>(
                  value: mode,
                  title: Text(label),
                  subtitle: Text(sub, style: AppText.small),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
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
        const Text('נוסח הברכות', style: TextStyle(color: AppColors.muted)),
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
        const Text('אצלנו בבית', style: TextStyle(color: AppColors.muted)),
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
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        BrassButton(label: 'סיימנו', onPressed: _saving ? null : _finish),
      ],
    );
  }
}
