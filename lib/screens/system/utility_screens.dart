import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                    _page == _pages.length - 1 ? 'Meet the Family' : 'Next',
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleListScreen(
      title: 'Settings',
      items: [
        ('Sound & Music', Icons.volume_up_rounded, '/sound'),
        ('Profile', Icons.person_rounded, '/profile'),
        ('Calendar / Streak', Icons.calendar_today_rounded, '/calendar'),
        ('Parent Dashboard', Icons.dashboard_rounded, '/parent-dashboard'),
        ('Help', Icons.help_outline_rounded, '/help'),
        ('Sticker Book', Icons.collections_bookmark_rounded, '/stickers'),
        ('Room Customize', Icons.chair_rounded, '/room'),
        ('Wardrobe', Icons.checkroom_rounded, '/wardrobe'),
        ('Achievements', Icons.emoji_events_rounded, '/achievements'),
      ],
    );
  }
}

class _SimpleListScreen extends StatelessWidget {
  const _SimpleListScreen({required this.title, required this.items});

  final String title;
  final List<(String, IconData, String)> items;

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
                  TtBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Text(title, style: TTTypography.headline()),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return BounceButton(
                    onPressed: () => context.push(item.$3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: TTColors.creamWhite,
                        borderRadius:
                            BorderRadius.circular(TTSpacing.radiusMd),
                        boxShadow: TTShadows.soft,
                      ),
                      child: Row(
                        children: [
                          Icon(item.$2, color: TTColors.skyDeep),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(item.$1, style: TTTypography.body()),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
