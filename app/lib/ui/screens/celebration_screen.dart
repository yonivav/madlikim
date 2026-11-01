import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import 'songs_screen.dart';

/// Vision 28.7: the app's one orchestrated moment. Candles catch one by one
/// in lighting order, sparks rise, then "+N אור".
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

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  final Set<int> _lit = {};
  bool _shamash = false;
  bool _done = false;
  Timer? _timer;
  late final String _line;
  late final AnimationController _sparks = AnimationController(
      vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider);
    _line = widget.late
        ? content.randomLine('lateCelebrations')
        : content.randomLine('celebrations');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _done) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final order = Menorah.lightingOrder(widget.night.number).entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (still) {
      _shamash = true;
      _lit.addAll(order.map((e) => e.key));
      _done = true;
      return;
    }
    _sparks.repeat();
    var i = -1; // shamash first
    _timer = Timer.periodic(const Duration(milliseconds: 420), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (i < 0) {
          _shamash = true;
        } else if (i < order.length) {
          _lit.add(order[i].key);
          HapticFeedback.selectionClick();
        } else {
          _done = true;
          t.cancel();
          HapticFeedback.mediumImpact();
        }
        i++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sparks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final score = ref.watch(scoreProvider);
    final newBadges = score.badges.difference(widget.badgesBefore);
    final placed = {for (var i = 0; i < widget.night.number; i++) i};

    return Scaffold(
      backgroundColor: AppColors.skyDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: 1.0,
            colors: [Color(0xFF2B2A3F), Color(0xFF17192D), AppColors.skyDeep],
            stops: [0, .4, .75],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sparks,
                  builder: (_, __) => CustomPaint(
                    painter: _SparksPainter(
                      t: _sparks.value,
                      strength: (_lit.length / placed.length).clamp(0, 1),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Menorah(
                    placed: placed,
                    lit: _lit,
                    shamashLit: _shamash,
                    height: 250,
                  ),
                  const SizedBox(height: 26),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _done ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      offset: _done ? Offset.zero : const Offset(0, .3),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('+${widget.light}',
                                  textDirection: TextDirection.ltr,
                                  style: _plus),
                              const SizedBox(width: 10),
                              const Text('אור', style: _plus),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Text(_line,
                                textAlign: TextAlign.center,
                                style: AppText.body
                                    .copyWith(fontSize: 20, height: 1.45)),
                          ),
                          if (score.currentStreak >= 2) ...[
                            const SizedBox(height: 8),
                            Text('${score.currentStreak} לילות ברצף',
                                style: AppText.small),
                          ],
                          for (final b in newBadges)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OlivePill(
                                emoji: badgeInfo[b]!.emoji,
                                text:
                                    '${badgeInfo[b]!.title}: ${badgeInfo[b]!.howTo}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Column(
                      children: [
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
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (_) => const SongsScreen())),
                          child: const Text('מעוז צור, עם אקורדים'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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
    fontFamily: AppText.serif,
    fontSize: 46,
    fontWeight: FontWeight.w800,
    color: AppColors.flame,
    shadows: [Shadow(color: Color(0x73FFC861), blurRadius: 24)],
  );
}

/// Sparks rising from the hanukkiah. Deterministic, looping.
class _SparksPainter extends CustomPainter {
  _SparksPainter({required this.t, required this.strength});
  final double t;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final r = math.Random(11);
    final origin = Offset(size.width / 2, size.height * .42);
    for (var i = 0; i < 26; i++) {
      final speed = .5 + r.nextDouble();
      final offset = r.nextDouble();
      final drift = (r.nextDouble() - .5) * size.width * .5;
      final p = (t * speed + offset) % 1.0;
      final pos = origin + Offset(drift * p + math.sin((p + offset) * 9) * 8,
          -p * size.height * .38);
      final alpha = (1 - p) * strength * (.4 + r.nextDouble() * .6);
      final radius = 1.2 + r.nextDouble() * 1.4;
      canvas.drawCircle(
        pos,
        radius * 3,
        Paint()..color = AppColors.flame.withValues(alpha: alpha * .18),
      );
      canvas.drawCircle(
          pos, radius, Paint()..color = AppColors.flame.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) =>
      old.t != t || old.strength != strength;
}
