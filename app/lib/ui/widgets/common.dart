import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/place.dart';
import '../../models/user_profile.dart';
import '../../state/providers.dart';
import '../theme.dart';

/// Picks the right form of a phrase (Vision 6: אתה / את / אתם).
String say(AddressForm form,
        {required String m, required String f, required String p}) =>
    switch (form) {
      AddressForm.male => m,
      AddressForm.female => f,
      AddressForm.plural => p,
    };

/// "16:42", at the user's place.
String hhmm(DateTime utc, Place place) {
  final l = tz.TZDateTime.from(utc, tz.getLocation(place.timeZone));
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// "ערב טוב" etc. by the local hour.
String greeting(DateTime utc, Place place) {
  final h = tz.TZDateTime.from(utc, tz.getLocation(place.timeZone)).hour;
  if (h >= 5 && h < 12) return 'בוקר טוב';
  if (h >= 12 && h < 17) return 'צהריים טובים';
  if (h >= 17 && h < 22) return 'ערב טוב';
  return 'לילה טוב';
}

/// Hebrew letter for nights 1..8 with a geresh: א׳ … ח׳.
String nightLetter(int night) => '${'אבגדהוזח'[night - 1]}׳';

Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// A display name is only needed for the social layer (invites, groups,
/// nudges). Call this right before such an action: if the profile already
/// has a name it returns it immediately; otherwise it asks for one, saves
/// it, and returns it. Returns null if the user cancels.
Future<String?> ensureDisplayName(BuildContext context, WidgetRef ref) async {
  final profile = ref.read(profileProvider)!;
  if (profile.displayName.isNotEmpty) return profile.displayName;
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('איך לקרוא לך?'),
      content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'השם שלך')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('אישור')),
      ],
    ),
  );
  if (name == null || name.isEmpty) return null;
  await ref
      .read(profileProvider.notifier)
      .save(profile.copyWith(displayName: name));
  return name;
}

/// The primary action: a brass bar that glows a little.
class BrassButton extends StatelessWidget {
  const BrassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : .55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.brassHi, AppColors.brass],
                  )
                : null,
            color: enabled ? null : AppColors.glass,
            boxShadow: enabled
                ? const [
                    BoxShadow(
                        color: Color(0x47D9A441),
                        blurRadius: 30,
                        offset: Offset(0, 10)),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    }
                  : null,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon,
                          size: 20,
                          color: enabled ? AppColors.ink : AppColors.mist),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.sans,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: enabled ? AppColors.ink : AppColors.mist,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain row with a hairline above it. Lists on this app are rows, not a
/// stack of identical cards.
class HairlineRow extends StatelessWidget {
  const HairlineRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.first = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// No line above the first row in a group.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.small),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_left, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}

/// A raised surface for things that need one (blessings, settings groups).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.highlight = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16223D), Color(0xFF121C33)],
          ),
          border: Border.all(
            color: highlight
                ? AppColors.brass.withValues(alpha: .7)
                : AppColors.brass.withValues(alpha: .14),
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GoldBanner extends StatelessWidget {
  const GoldBanner(this.text, {super.key, this.icon = Icons.wb_twilight});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brass.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brass.withValues(alpha: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brass, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 15))),
        ],
      ),
    );
  }
}

/// An earned thing (badge), in olive.
class OlivePill extends StatelessWidget {
  const OlivePill({super.key, required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.olive.withValues(alpha: .1),
        border: Border.all(color: AppColors.olive.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 10),
          Text(text, style: AppText.body.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

/// Shown in debug builds next to content that no rabbi has reviewed yet.
class UnreviewedMark extends StatelessWidget {
  const UnreviewedMark({super.key, required this.reviewed});
  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    if (reviewed || !debug) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsetsDirectional.only(end: 12),
      child: Tooltip(
        message: 'התוכן עוד לא נבדק על ידי רב',
        child: Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.ember),
      ),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
