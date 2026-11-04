import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/neri.dart';
import '../widgets/scene.dart';
import 'songs_screen.dart';

/// The one big moment: Neri catches fire, tonight's buddies light up one by
/// one, confetti falls, "+N אור".
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
  int _litCount = 0;
  bool _neriLit = false;
  bool _done = false;
  Timer? _timer;
  late final String _line;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider);
    _line = widget.late
        ? content.randomLine('lateCelebrations')
        : content.text('neri.celebrate');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _done) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final n = widget.night.number;
    if (still) {
      _neriLit = true;
      _litCount = n;
      _done = true;
      return;
    }
    var step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 380), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (step == 0) {
          _neriLit = true; // the shamash
          HapticFeedback.mediumImpact();
        } else if (_litCount < n) {
          _litCount++;
          HapticFeedback.selectionClick();
        } else {
          _done = true;
          t.cancel();
          HapticFeedback.heavyImpact();
        }
        step++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final score = ref.watch(scoreProvider);
    final newBadges = score.badges.difference(widget.badgesBefore);
    final n = widget.night.number;
    final buddy = (MediaQuery.sizeOf(context).width - 48) / 8.6;

    return Scaffold(
      backgroundColor: AppColors.night,
      body: NightBackdrop(
        child: Stack(
          children: [
            if (_neriLit) const Positioned.fill(child: ConfettiFall()),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Neri(
                    size: 190,
                    mood: _done ? NeriMood.excited : NeriMood.happy,
                    arms: _neriLit ? NeriArms.up : NeriArms.down,
                    lit: _neriLit,
                    semanticLabel: 'נרי שמח',
                  ),
                  const SizedBox(height: 10),
                  // Tonight's buddies, lighting one by one (newest first).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < n; i++)
                        Neri(
                          size: buddy,
                          color: NeriColor.forNight(i + 1),
                          mood: i >= n - _litCount ? NeriMood.happy : NeriMood.calm,
                          lit: i >= n - _litCount,
                          glow: .5,
                          animate: false,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _done ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      offset: _done ? Offset.zero : const Offset(0, .3),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('+${widget.light}', textDirection: TextDirection.ltr, style: _plus),
                              const SizedBox(width: 12),
                              const Text('אור', style: _plus),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                            child: SpeechBubble(_line, tail: false),
                          ),
                          if (score.currentStreak >= 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: InkChip(text: '🔥 ${score.currentStreak} לילות ברצף'),
                            ),
                          for (final b in newBadges)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OlivePill(
                                emoji: badgeInfo[b]!.emoji,
                                text: 'תג חדש: ${badgeInfo[b]!.title}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 8),
                    child: Column(
                      children: [
                        BrassButton(
                          label: 'לשתף את החבר\'ה',
                          icon: Icons.ios_share,
                          onPressed: () {
                            ref.read(localStoreProvider).logEvent('share_tapped', {'kind': 'lit'});
                            shareText(content.text('share.lit', vars: {
                              'title': widget.night.title,
                              'link': content.appLink,
                            }));
                          },
                        ),
                        const SizedBox(height: 12),
                        BrassButton(
                          label: 'מעוז צור, עם אקורדים',
                          ghost: true,
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
    fontSize: 54,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
    shadows: [Shadow(color: Color(0xFFB3561C), offset: Offset(0, 3))],
  );
}
