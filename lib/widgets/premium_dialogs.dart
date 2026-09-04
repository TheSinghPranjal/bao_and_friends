import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/premium_store.dart';
import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart';
import 'bao_face.dart';
import 'bounce_button.dart';

/// Shown when a section has 0 remaining taps — Buy Premium only.
Future<void> showOutOfTapsDialog(
  BuildContext context, {
  required ActivitySection section,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Out of taps',
    barrierColor: TTColors.darkBrown.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, _) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _OutOfTapsCard(section: section),
        ),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

class _OutOfTapsCard extends StatelessWidget {
  const _OutOfTapsCard({required this.section});

  final ActivitySection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusLg),
        boxShadow: TTShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BaoFace(size: 72),
          const SizedBox(height: 12),
          Text(
            '${section.label} taps used up!',
            textAlign: TextAlign.center,
            style: TTTypography.title(color: TTColors.darkBrown),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve used today\'s ${PremiumStore.maxTapsPerSection} free taps '
            'for ${section.label}. Unlock Premium for unlimited play, '
            'or come back tomorrow!',
            textAlign: TextAlign.center,
            style: TTTypography.body(color: TTColors.softBrown),
          ),
          const SizedBox(height: 18),
          BounceButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium');
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 54),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE066),
                    TTColors.golden,
                  ],
                ),
                borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
                boxShadow: TTShadows.soft,
              ),
              child: Text(
                'Buy Premium',
                style: TTTypography.button(color: TTColors.darkBrown),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not now',
              style: TTTypography.caption(color: TTColors.softBrown),
            ),
          ),
        ],
      ),
    );
  }
}
