import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';
import '../../widgets/status_bar.dart';

/// Shared hub scaffold used by Learn / Feed / Play / Chores.
class ModuleHubScreen extends StatelessWidget {
  const ModuleHubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.items,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<HubItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.35),
              TTColors.cream,
            ],
          ),
        ),
        child: Column(
          children: [
            TinyStatusBar(
              onSettings: () => context.push('/parent-gate'),
              leading: TtBackButton(onPressed: () => context.pop()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Column(
                children: [
                  Text(title, style: TTTypography.headline()),
                  Text(subtitle, style: TTTypography.subtitle()),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return BounceButton(
                    onPressed: () {
                      if (item.route != null) {
                        context.push(item.route!);
                      } else {
                        context.push(
                          '/activity?title=${Uri.encodeComponent(item.label)}&module=${Uri.encodeComponent(title)}',
                        );
                      }
                    },
                    semanticLabel: item.label,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TTColors.creamWhite,
                        borderRadius:
                            BorderRadius.circular(TTSpacing.radiusLg),
                        border: Border.all(color: accent, width: 3),
                        boxShadow: TTShadows.soft,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 40, color: accent),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: TTTypography.subtitle(
                              color: TTColors.darkBrown,
                            ),
                          ),
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

class HubItem {
  const HubItem(this.label, this.icon, {this.route});
  final String label;
  final IconData icon;
  final String? route;
}

/// Generic activity screen with looping video placeholder + reward CTA.
class ActivityPlaceholderScreen extends StatefulWidget {
  const ActivityPlaceholderScreen({
    super.key,
    required this.title,
    required this.module,
  });

  final String title;
  final String module;

  @override
  State<ActivityPlaceholderScreen> createState() =>
      _ActivityPlaceholderScreenState();
}

class _ActivityPlaceholderScreenState extends State<ActivityPlaceholderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TTColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TTSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  TtBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TTTypography.title(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.module,
                style: TTTypography.caption(),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (0.5 - _bounce.value) * 10),
                    child: child,
                  );
                },
                child: VideoPlaceholder(
                  label: '${widget.title} loop – placeholder',
                  width: double.infinity,
                  height: 220,
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 72,
                      color: TTColors.skyDeep.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _done
                    ? 'Great job! Bao is so proud.'
                    : 'Tap to play with Bao!',
                style: TTTypography.body(),
              ),
              const Spacer(),
              BounceButton(
                onPressed: () {
                  if (_done) {
                    context.pop();
                    return;
                  }
                  setState(() => _done = true);
                },
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
                    _done ? 'Collect ★ Star' : 'Tap with Bao',
                    style: TTTypography.button(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
