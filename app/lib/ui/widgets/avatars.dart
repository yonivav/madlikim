import 'package:flutter/material.dart';

import '../../social/social_models.dart';
import '../theme.dart';

const _tones = [
  Color(0xFF7FB0FF),
  Color(0xFFFFD95C),
  Color(0xFFFFA8C2),
  Color(0xFF86E3C2),
  Color(0xFFFFB17A),
  Color(0xFFBBA2FF),
];

Color toneFor(String id) => _tones[id.hashCode.abs() % _tones.length];

/// A round initial. When [lit], a small flame sits on top.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.member, this.lit = false, this.size = 34});
  final GroupMember member;
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = member.name.isEmpty ? '?' : member.name.characters.first;
    return SizedBox(
      width: size,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.3, -.5),
                colors: [Color.lerp(toneFor(member.id), Colors.white, .45)!, toneFor(member.id)],
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: Gloss.soft(4),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: TextStyle(
                    fontSize: size * .42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ),
          if (lit) const Positioned(top: 0, child: _TinyFlame()),
        ],
      ),
    );
  }
}

class _TinyFlame extends StatelessWidget {
  const _TinyFlame();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 10,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(5), bottom: Radius.circular(3.5)),
          gradient: RadialGradient(
            center: Alignment(0, .4),
            colors: [AppColors.flameCore, AppColors.flame, AppColors.ember],
            stops: [0, .55, 1],
          ),
          boxShadow: [BoxShadow(color: AppColors.flame, blurRadius: 8)],
        ),
      );
}

/// Up to three avatars, lit ones first, plus a "+N".
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, required this.litIds});
  final List<GroupMember> members;
  final Set<String> litIds;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final sorted = [...members]
      ..sort((a, b) => (litIds.contains(b.id) ? 1 : 0) - (litIds.contains(a.id) ? 1 : 0));
    final shown = sorted.take(3).toList();
    final rest = members.length - shown.length;
    const overlap = 26.0;
    final count = shown.length + (rest > 0 ? 1 : 0);
    return SizedBox(
      width: overlap * (count - 1) + 34,
      height: 40,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              end: i * overlap,
              bottom: 0,
              child: Avatar(member: shown[i], lit: litIds.contains(shown[i].id)),
            ),
          if (rest > 0)
            PositionedDirectional(
              end: shown.length * overlap,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Gloss.pearlGradient,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: Gloss.soft(4),
                ),
                alignment: Alignment.center,
                child: Text('+$rest',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}
