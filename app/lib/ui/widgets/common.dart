import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Hebrew letter for nights 1..8 with a geresh: א׳ … ח׳.
String nightLetter(int night) => '${'אבגדהוזח'[night - 1]}׳';

Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// The primary action: an orange pill with an ink outline and a hard shadow.
/// [ghost] makes it white (secondary).
class BrassButton extends StatefulWidget {
  const BrassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emoji,
    this.height = 58,
    this.ghost = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shown after the label (e.g. 🔥), kept out of the label so tests and
  /// screen readers get clean text.
  final String? emoji;
  final double height;
  final bool ghost;

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = !enabled
        ? AppColors.muted
        : widget.ghost
            ? AppColors.ink
            : Colors.white;
    final press = _down ? 3.0 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: widget.height,
          width: double.infinity,
          transform: Matrix4.translationValues(0, press, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            gradient: enabled && !widget.ghost
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.orangeHi, AppColors.orange],
                  )
                : null,
            color: !enabled
                ? AppColors.paper2
                : widget.ghost
                    ? AppColors.card
                    : null,
            border: Border.all(color: enabled ? AppColors.ink : AppColors.muted, width: 2),
            boxShadow: enabled ? Ink2.shadow(0, 4 - press) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(widget.label,
                    textAlign: TextAlign.center,
                    style: AppText.button.copyWith(color: fg)),
              ),
              if (widget.emoji != null) ...[
                const SizedBox(width: 8),
                Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Neri's speech bubble: cream pill, ink outline, little tail.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(this.text, {super.key, this.tail = true});
  final String text;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (tail)
          Positioned(
            bottom: -8,
            child: Transform.rotate(
              angle: .785,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBF2),
                  border: Border(
                    right: Ink2.border,
                    bottom: Ink2.border,
                  ),
                ),
              ),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(text),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: Ink2.shadow(),
            ),
            child: Text(text,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 15.5, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

/// The Hebrew date in a little calendar tile ("כ״ח / כסלו").
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.day, required this.month});
  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: Ink2.shadow(2, 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(day,
                style: const TextStyle(
                    fontFamily: AppText.serif, fontSize: 21, fontWeight: FontWeight.w700, height: 1.3)),
          ),
          Container(
            width: double.infinity,
            color: AppColors.blue,
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(month,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// A small outlined chip ("🔥 3").
class InkChip extends StatelessWidget {
  const InkChip({super.key, required this.text, this.color = AppColors.card});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: Ink2.shadow(2, 2),
        ),
        child: Text(text,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontFamily: AppText.round, fontSize: 15, fontWeight: FontWeight.w600)),
      );
}

/// Round outlined action with a label under it.
class CircleAction extends StatelessWidget {
  const CircleAction({super.key, required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: Ink2.shadow(2, 3),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppText.small.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain row with a hairline above it.
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
  final bool first;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: first ? null : const Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              const Icon(Icons.chevron_left, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// A raised card: cream, ink outline, hard shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.highlight = false,
    this.color = AppColors.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF4D6) : color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: Ink2.shadow(3, 4),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 15))),
        ],
      ),
    );
  }
}

/// An earned badge.
class OlivePill extends StatelessWidget {
  const OlivePill({super.key, required this.emoji, required this.text, this.earned = true});
  final String emoji;
  final String text;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1 : .4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color: earned ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: earned ? Ink2.shadow(2, 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 8),
            Text(text, style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
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
