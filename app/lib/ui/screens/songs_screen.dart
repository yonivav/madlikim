import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('אחרי ההדלקה'),
        actions: [UnreviewedMark(reviewed: content.reviewed)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final song in content.songList) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(song.when,
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 16),
                  Text(
                    song.text,
                    style: const TextStyle(
                        fontFamily: AppTheme.blessingFont,
                        fontSize: 22,
                        height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
