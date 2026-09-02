import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';

/// Orange due badge matching Play game bubbles.
class DueCountBadge extends StatelessWidget {
  const DueCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Positioned(
      right: -2,
      top: -2,
      child: Container(
        constraints: const BoxConstraints(minWidth: 26),
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TTColors.ribbonOrange,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: TTShadows.soft,
        ),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Horizontal bottom row of chore bubbles (Play-style placement).
List<Widget> choreBubblesAlongBottom({
  required int count,
  required double maxWidth,
  required double bubbleSize,
  required double bob,
  required Widget Function(int index, double left, double bottom) buildAt,
}) {
  if (count <= 0) return const [];
  final spacing = maxWidth / (count + 1);
  return [
    for (var i = 0; i < count; i++)
      buildAt(
        i,
        spacing * (i + 1) - bubbleSize / 2,
        48 + bob + (i.isOdd ? -bob * 0.35 : 0),
      ),
  ];
}
