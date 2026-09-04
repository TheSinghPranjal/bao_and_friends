import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/music_store.dart';
import '../../services/premium_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bao_face.dart';
import '../../widgets/bounce_button.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      'Welcome to Tiny Think',
      'A magical family world where Bao learns with you.',
      Icons.auto_awesome_rounded,
    ),
    (
      'Meet the Family',
      'Bao, Poko, and more friends are waiting to play.',
      Icons.family_restroom_rounded,
    ),
    (
      'How to Play',
      'Tap big bubbles. Learn, sip water, play, and help with chores!',
      Icons.touch_app_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      context.go('/select');
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TTColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BaoFace(size: 120),
                        const SizedBox(height: 24),
                        Icon(p.$3, size: 48, color: TTColors.skyDeep),
                        const SizedBox(height: 16),
                        Text(
                          p.$1,
                          textAlign: TextAlign.center,
                          style: TTTypography.headline(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.$2,
                          textAlign: TextAlign.center,
                          style: TTTypography.body(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return Container(
                  width: i == _page ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: i == _page ? TTColors.golden : TTColors.peachDeep,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: BounceButton(
                onPressed: _next,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 64),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TTColors.golden,
                    borderRadius: BorderRadius.circular(TTSpacing.radiusPill),
                    boxShadow: TTShadows.soft,
                  ),
                  child: Text(
                    _page >= _pages.length - 1 ? 'Meet the Family' : 'Next',
                    style: TTTypography.button(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parent Settings — music, premium testing toggle, activity timers.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _premiumUnlocked = false;
  bool _musicOn = true;
  bool _loaded = false;
  Map<ActivitySection, int> _remaining = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final unlocked = await PremiumStore.isPremiumUnlocked();
    final music = await MusicStore.isEnabled();
    final remaining = await PremiumStore.remainingBySection();
    if (!mounted) return;
    setState(() {
      _premiumUnlocked = unlocked;
      _musicOn = music;
      _remaining = remaining;
      _loaded = true;
    });
  }

  Future<void> _setPremium(bool value) async {
    setState(() => _premiumUnlocked = value);
    await PremiumStore.setPremiumUnlocked(value);
    final remaining = await PremiumStore.remainingBySection();
    if (!mounted) return;
    setState(() => _remaining = remaining);
  }

  Future<void> _setMusic(bool value) async {
    setState(() => _musicOn = value);
    await MusicStore.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TTColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TtBackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/select');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Parent Settings',
                      style: TTTypography.headline(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _SettingsToggleCard(
                    icon: Icons.music_note_rounded,
                    title: 'Music',
                    subtitle: _musicOn
                        ? 'On — background music enabled'
                        : 'Off — music muted',
                    loaded: _loaded,
                    value: _musicOn,
                    onChanged: _setMusic,
                    active: _musicOn,
                  ),
                  const SizedBox(height: 12),
                  _SettingsToggleCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Premium subscription',
                    subtitle: _premiumUnlocked
                        ? 'On — unlimited activities (testing)'
                        : 'Off — ${PremiumStore.maxTapsPerSection} taps / section / day',
                    loaded: _loaded,
                    value: _premiumUnlocked,
                    onChanged: _setPremium,
                    active: _premiumUnlocked,
                  ),
                  const SizedBox(height: 12),
                  BounceButton(
                    onPressed: () => context.push('/activity-timers'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: TTColors.creamWhite,
                        borderRadius:
                            BorderRadius.circular(TTSpacing.radiusLg),
                        boxShadow: TTShadows.soft,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_rounded,
                            color: TTColors.skyDeep,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Activity Timers',
                              style: TTTypography.title(
                                color: TTColors.darkBrown,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: TTColors.softBrown,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loaded) ...[
                    const SizedBox(height: 20),
                    _RemainingTapsCard(remaining: _remaining),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  const _SettingsToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loaded,
    required this.value,
    required this.onChanged,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool loaded;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusLg),
        border: Border.all(
          color: active ? TTColors.golden : TTColors.peachDeep,
          width: 2,
        ),
        boxShadow: TTShadows.soft,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? TTColors.goldenOutline : TTColors.skyDeep,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TTTypography.title(color: TTColors.darkBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TTTypography.caption(color: TTColors.softBrown),
                ),
              ],
            ),
          ),
          if (!loaded)
            const SizedBox(
              width: 48,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Switch.adaptive(
              value: value,
              activeTrackColor: TTColors.golden,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _RemainingTapsCard extends StatelessWidget {
  const _RemainingTapsCard({required this.remaining});

  final Map<ActivitySection, int> remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusLg),
        boxShadow: TTShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taps left today',
            style: TTTypography.title(color: TTColors.darkBrown),
          ),
          const SizedBox(height: 8),
          for (final s in ActivitySection.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.label,
                      style: TTTypography.body(color: TTColors.darkBrown),
                    ),
                  ),
                  Text(
                    '${remaining[s] ?? PremiumStore.maxTapsPerSection}',
                    style: TTTypography.title(color: TTColors.bambooDeep),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PlaceholderInfoScreen extends StatelessWidget {
  const PlaceholderInfoScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TTColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TtBackButton(onPressed: () => context.pop()),
              ),
              const Spacer(),
              const BaoFace(size: 96),
              const SizedBox(height: 16),
              Text(title, style: TTTypography.headline()),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TTTypography.body(),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
