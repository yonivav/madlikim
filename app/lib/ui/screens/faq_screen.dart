import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Vision 28.12: short questions, 2 to 4 line answers.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('למה ואיך'),
        actions: [UnreviewedMark(reviewed: content.reviewed)],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: content.faqList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = content.faqList[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: AppColors.gold,
              title: Text(item.question,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: AlignmentDirectional.centerStart,
              children: [
                Text(item.answer,
                    style:
                        const TextStyle(height: 1.5, color: AppColors.silver)),
              ],
            ),
          );
        },
      ),
    );
  }
}
