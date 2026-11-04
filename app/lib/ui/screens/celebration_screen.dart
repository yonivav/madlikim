import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lighting_show.dart';
import '../widgets/my_neri.dart';
import '../widgets/scene.dart';
import 'songs_screen.dart';

/// The one big moment: "passing the flame" (see [LightingShow]), then
/// "+N אור", a line from the user's candle, and what to do next.
class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.night,
    required this.light,
    this.late = false,
    this.badgesBefore = const {},
  });

  final HanukkahNight night;
  final int light;
  final bool late;

  /// Badges the user had before this lighting, to show only the new ones.
  final Set<Achievement> badgesBefore;

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen> {
  bool _done = false;
  late final String _line;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider);
    _line = widget.late
        ? content.randomLine('lateCelebrations')
        : buddyLine(content, ref.read(myNeriProvider), 'celebrate',
            index: widget.night.number);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final score = ref.watch(scoreProvider);
    final me = ref.watch(myNeriProvider);
    final newBadges = score.badges.difference(widget.badgesBefore);

    return Scaffold(
      backgroundColor: AppColors.night,
      body: NightBackdrop(
        child: Stack(
          children: [
            if (_done) const Positioned.fill(child: IgnorePointer(child: ConfettiFall())),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LightingShow(
                        night: widget.night.number,
                        me: me.look,
                        onDone: () {
                          if (mounted) setState(() => _done = true);
                        },
                      ),
                    ),
                  ),
                  // The panel slides in after the show; until then the show
                  // gets the whole screen and then shrinks to make room.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    child: !_done
                        ? const SizedBox(width: double.infinity)
                        : TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (context, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 0, 26, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('+${widget.light}',
                                      textDirection: TextDirection.ltr, style: _plus),
                                  const SizedBox(width: 12),
                                  const Text('אור', style: _plus),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
                                child: SpeechBubble(_line, tail: false),
                              ),
                              if (score.currentStreak >= 2 || newBadges.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      if (score.currentStreak >= 2)
                                        InkChip(text: '🔥 ${score.currentStreak} לילות ברצף'),
                                      for (final b in newBadges)
                                        OlivePill(
                                          emoji: badgeInfo[b]!.emoji,
                                          text: 'תג חדש: ${badgeInfo[b]!.title}',
                                          labelColor: AppColors.onNight,
                                          width: 120,
                                        ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              BrassButton(
                                label: 'לשתף את החבר\'ה',
                                icon: Icons.ios_share,
                                onPressed: () {
                                  ref
                                      .read(localStoreProvider)
                                      .logEvent('share_tapped', {'kind': 'lit'});
                                  shareText(content.text('share.lit', vars: {
                                    'title': widget.night.title,
                                    'link': content.appLink,
                                  }));
                                },
                              ),
                              const SizedBox(height: 12),
                              BrassButton(
                                label: 'מעוז צור, עם אקורדים',
                                night: true,
                                onPressed: () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const SongsScreen())),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(foregroundColor: AppColors.onNight),
                                child: const Text('חזרה לבית'),
                              ),
                            ],
                          ),
                        ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _plus = TextStyle(
    fontFamily: AppText.round,
    fontSize: 46,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
    shadows: [Shadow(color: Color(0x99FFC63A), blurRadius: 22)],
  );
}
