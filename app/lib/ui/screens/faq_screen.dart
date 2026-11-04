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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          for (var i = 0; i < content.faqList.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: AppColors.orange,
                  collapsedIconColor: AppColors.muted,
                  title: Text(content.faqList[i].question,
                      style: AppText.heading),
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  expandedAlignment: AlignmentDirectional.centerStart,
                  children: [
                    Text(content.faqList[i].answer,
                        style: AppText.body.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
