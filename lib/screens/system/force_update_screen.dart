import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/force_update_service.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart'; // TTTypography, TTSpacing
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';

/// Blocking screen — user must update before continuing.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.decision});

  final ForceUpdateDecision decision;

  Future<void> _openStore() async {
    final uri = Uri.parse(decision.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: TTColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                const BaoFace(size: 120),
                const SizedBox(height: 24),
                Text(
                  'Time to update!',
                  textAlign: TextAlign.center,
                  style: TTTypography.headline(),
                ),
                const SizedBox(height: 12),
                Text(
                  'A newer version of Bao & Friends is ready on the Play Store. '
                  'Please update to keep playing with Bao.',
                  textAlign: TextAlign.center,
                  style: TTTypography.body(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TTColors.creamWhite,
                    borderRadius: BorderRadius.circular(TTSpacing.radiusMd),
                    boxShadow: TTShadows.soft,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your version: ${decision.currentVersion}',
                        style: TTTypography.subtitle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required: ${decision.minimumVersion.isNotEmpty ? decision.minimumVersion : decision.latestVersion}',
                        style: TTTypography.subtitle(color: TTColors.skyDeep),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                BounceButton(
                  onPressed: _openStore,
                  semanticLabel: 'Update now',
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 64),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TTColors.golden,
                      borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
                      boxShadow: TTShadows.soft,
                    ),
                    child: Text('Update now', style: TTTypography.button()),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You need this update to continue.',
                  style: TTTypography.caption(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
