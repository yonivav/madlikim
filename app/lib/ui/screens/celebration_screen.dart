import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hanukkah.dart';
import '../../logic/scoring.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menorah.dart';
import 'songs_screen.dart';

/// Vision 28.7: candles light one by one, "+N אור", a warm line, a badge.
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
  final Set<int> _lit = {};
  Timer? _timer;
  late final String _line;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider);
    _line = widget.late
        ? content.randomLine('lateCelebrations')
        : content.randomLine('celebrations');
    // Light in order: newest (leftmost) first.
    final order = Menorah.lightingOrder(widget.night.number);
    final sequence = order.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    var i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 450), (t) {
      if (i >= sequence.length) {
        t.cancel();
        return;
      }
      setState(() => _lit.add(sequence[i++].key));
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
    final placed = {for (var i = 0; i < widget.night.number; i++) i};

    return Scaffold(
      backgroundColor: AppColors.nightDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Menorah(
                placed: placed,
                lit: _lit,
                shamashLit: true,
                height: 220,
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                      offset: Offset(0, 20 * (1 - v)), child: child),
                ),
                child: Text('+${widget.light} אור ✨',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold)),
              ),
              const SizedBox(height: 12),
              Text(_line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, height: 1.4)),
              const SizedBox(height: 8),
              if (score.currentStreak >= 2)
                Text('${score.currentStreak} לילות ברצף',
                    style: const TextStyle(color: AppColors.silver)),
              for (final b in newBadges)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Chip(
                    avatar: Text(badgeInfo[b]!.emoji),
                    label: Text('תג חדש: ${badgeInfo[b]!.title}'),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(localStoreProvider)
                      .logEvent('share_tapped', {'kind': 'lit'});
                  shareText(content.text('share.lit', vars: {
                    'title': widget.night.title,
                    'link': content.appLink,
                  }));
                },
                icon: const Icon(Icons.share),
                label: const Text('לשתף עם החבר\'ה'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SongsScreen())),
                child: const Text('הנרות הללו / מעוז צור'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('לחזור לבית'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
