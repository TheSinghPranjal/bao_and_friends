import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/premium_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';

/// Daily free-limit paywall — Learn / Play / Feed / Chores locked until
/// premium is unlocked or a new calendar day starts.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.fromSettings = false});

  /// When opened from Settings, back always pops. When shown as a lock,
  /// back returns home but activities stay locked for the day.
  final bool fromSettings;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _busy = false;

  Future<void> _buyPremium() async {
    if (_busy) return;
    setState(() => _busy = true);
    await PremiumStore.setPremiumUnlocked(true);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Premium unlocked! Enjoy unlimited play.',
          style: TTTypography.body(color: TTColors.creamWhite),
        ),
        backgroundColor: TTColors.bambooDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/select');
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go('/select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE8A0),
                  TTColors.cream,
                  Color(0xFFFFF0E0),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _close,
                      icon: const Icon(Icons.close_rounded),
                      color: TTColors.darkBrown,
                      iconSize: 32,
                    ),
                  ),
                  const Spacer(flex: 1),
                  const BaoFace(size: 110),
                  const SizedBox(height: 20),
                  Text(
                    'Bao needs Premium!',
                    textAlign: TextAlign.center,
                    style: TTTypography.headline(color: TTColors.darkBrown)
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You used today\'s ${PremiumStore.maxTapsPerSection} free '
                    'taps for this activity.\n\n'
                    'Unlock Premium for unlimited Learn, Play, Feed & Chores. '
                    'Free taps reset tomorrow!',
                    textAlign: TextAlign.center,
                    style: TTTypography.body(color: TTColors.softBrown),
                  ),
                  const SizedBox(height: 28),
                  _BenefitRow(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Unlimited Learn, Play, Feed & Chores',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Keep the adventure going all day',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(
                    icon: Icons.favorite_rounded,
                    label: 'Support Bao & Friends',
                  ),
                  const Spacer(flex: 2),
                  BounceButton(
                    onPressed: _busy ? null : _buyPremium,
                    enabled: !_busy,
                    semanticLabel: 'Get Premium',
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 64),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFE066),
                            TTColors.golden,
                            Color(0xFFE8B820),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(TTSpacing.radiusPill),
                        boxShadow: [
                          BoxShadow(
                            color: TTColors.goldenOutline.withValues(alpha: 0.45),
                            blurRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                          ...TTShadows.soft,
                        ],
                      ),
                      child: Text(
                        _busy ? 'Unlocking…' : 'Get Premium',
                        style: TTTypography.button(color: TTColors.darkBrown),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Free taps come back tomorrow',
                    style: TTTypography.caption(color: TTColors.softBrown),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TTColors.creamWhite.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(TTSpacing.radiusLg),
        boxShadow: TTShadows.soft,
      ),
      child: Row(
        children: [
          Icon(icon, color: TTColors.goldenOutline, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TTTypography.body(color: TTColors.darkBrown),
            ),
          ),
        ],
      ),
    );
  }
}
