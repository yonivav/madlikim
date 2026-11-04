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

/// The primary action: a glossy orange candy pill with a warm glow.
/// [ghost] makes it pearl white (secondary); [night] makes it frosted glass
/// for the dark screens.
class BrassButton extends StatefulWidget {
  const BrassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emoji,
    this.height = 60,
    this.ghost = false,
    this.night = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shown after the label (e.g. 🔥), kept out of the label so tests and
  /// screen readers get clean text.
  final String? emoji;
  final double height;
  final bool ghost;
  final bool night;

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
        : widget.night
            ? Colors.white
            : widget.ghost
                ? AppColors.ink
                : Colors.white;
    final decoration = !enabled
        ? BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(999),
          )
        : widget.night
            ? Gloss.glass()
            : widget.ghost
                ? Gloss.pearl()
                : Gloss.candy();
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
        child: AnimatedScale(
          scale: _down ? .96 : 1,
          duration: const Duration(milliseconds: 90),
          child: GlossBox(
            height: widget.height,
            width: double.infinity,
            decoration: decoration,
            shine: enabled ? (widget.ghost ? .9 : .45) : 0,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(widget.label,
                      textAlign: TextAlign.center,
                      style: AppText.button.copyWith(
                        color: fg,
                        shadows: !enabled || widget.ghost
                            ? null
                            : const [Shadow(color: Color(0x40A03200), offset: Offset(0, 1), blurRadius: 2)],
                      )),
                ),
                if (widget.emoji != null) ...[
                  const SizedBox(width: 8),
                  Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neri's speech bubble: a pearl pill with a thought-bubble tail of two dots.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(this.text, {super.key, this.tail = true});
  final String text;
  final bool tail;

  static const _fill = Color(0xFFFFF8EC);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (tail) ...[
          Positioned(
            bottom: -9,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: _fill, shape: BoxShape.circle, boxShadow: Gloss.soft(3)),
            ),
          ),
          Positioned(
            bottom: -21,
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: _fill, shape: BoxShape.circle, boxShadow: Gloss.soft(2)),
              ),
            ),
          ),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: GlossBox(
            key: ValueKey(text),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: Gloss.pearl(),
            shine: .9,
            child: Text(text,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 15.5, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

/// The Hebrew date on a glossy blue coin ("כ״ח / כסלו").
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.day, required this.month});
  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return GlossBox(
      width: 60,
      height: 60,
      decoration: Gloss.sky(shape: BoxShape.circle),
      shine: .4,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(day,
              style: const TextStyle(
                  fontFamily: AppText.serif,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: Colors.white)),
          Text(month,
              style: const TextStyle(
                  color: Color(0xE6FFFFFF), fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }
}

/// A small pearl chip ("🔥 3").
class InkChip extends StatelessWidget {
  const InkChip({super.key, required this.text, this.color = AppColors.card});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => GlossBox(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: color == AppColors.card
            ? Gloss.pearl(lift: 5)
            : BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: Gloss.rim,
                boxShadow: Gloss.soft(5),
              ),
        shine: .8,
        child: Text(text,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontFamily: AppText.round, fontSize: 15, fontWeight: FontWeight.w600)),
      );
}

/// A pearl bubble button with a label under it.
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
          width: 68,
          child: Column(
            children: [
              GlossBox(
                width: 56,
                height: 56,
                decoration: Gloss.pearl(shape: BoxShape.circle, lift: 7),
                shine: .9,
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(height: 5),
              Text(label, style: AppText.small.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row inside a card, separated by a soft hairline.
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
      borderRadius: BorderRadius.circular(24),
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
              Container(
                width: 30,
                height: 30,
                decoration: Gloss.pearl(shape: BoxShape.circle, lift: 3),
                child: const Icon(Icons.chevron_left, color: AppColors.muted, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

/// A raised pearl card with big round corners and a soft shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(22, 18, 22, 18),
    this.highlight = false,
    this.color = AppColors.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool highlight;
  final Color color;

  static const radius = 32.0;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final BoxDecoration deco = highlight
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9E4), Color(0xFFFFEDB8)],
            ),
            borderRadius: r,
            border: Gloss.rim,
            boxShadow: Gloss.glow(const Color(0xFFF2A91E), 8),
          )
        : color == AppColors.card
            ? Gloss.pearl(radius: r)
            : BoxDecoration(color: color, borderRadius: r, border: Gloss.rim, boxShadow: Gloss.soft());
    return Container(
      decoration: deco,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
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
    return GlossBox(
      padding: const EdgeInsets.fromLTRB(16, 12, 18, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7DA), Color(0xFFFFE9A8)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Gloss.rim,
        boxShadow: Gloss.glow(const Color(0xFFF2A91E), 6),
      ),
      shine: .7,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: Gloss.candy(shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: AppText.body.copyWith(fontSize: 15)),
          )),
        ],
      ),
    );
  }
}

/// A badge: a round coin with an emoji, its name under it. Earned coins
/// are honey gold; locked ones are a faint empty circle.
class OlivePill extends StatelessWidget {
  const OlivePill({
    super.key,
    required this.emoji,
    required this.text,
    this.earned = true,
    this.labelColor = AppColors.ink,
    this.width = 78,
  });
  final String emoji;
  final String text;
  final bool earned;
  final Color labelColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: earned ? text : '$text (עוד לא)',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Opacity(
          opacity: earned ? 1 : .45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlossBox(
                width: 60,
                height: 60,
                decoration: earned
                    ? Gloss.honey(shape: BoxShape.circle)
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x0F1E2340),
                        border: Border.all(color: const Color(0x1F1E2340), width: 2),
                      ),
                shine: earned ? .6 : 0,
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 5),
              Text(text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.small.copyWith(
                      fontSize: 11.5, height: 1.2, color: labelColor, fontWeight: FontWeight.w500)),
            ],
          ),
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
