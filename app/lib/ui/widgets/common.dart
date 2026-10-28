import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/place.dart';
import '../../models/user_profile.dart';
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

Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

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
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: highlight
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.gold, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
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
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.cream, height: 1.4)),
          ),
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
    return const Tooltip(
      message: 'התוכן עוד לא נבדק על ידי רב',
      child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
