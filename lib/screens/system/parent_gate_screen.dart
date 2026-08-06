import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/bounce_button.dart';

/// Simple math parent gate — tap-hold style for settings/store only.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key, this.nextRoute = '/settings'});

  final String nextRoute;

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  static const _a = 3;
  static const _b = 4;
  static const _answer = 7;
  int? _selected;
  String? _hint;

  void _submit(int value) {
    if (value == _answer) {
      context.go(widget.nextRoute);
      return;
    }
    setState(() {
      _selected = value;
      _hint = 'Try again — you\'ve got this!';
    });
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
              Align(
                alignment: Alignment.centerLeft,
                child: BounceButton(
                  onPressed: () => context.pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TTColors.creamWhite,
                      boxShadow: TTShadows.soft,
                    ),
                    child: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              const Spacer(),
              Text('Grown-ups only', style: TTTypography.headline()),
              const SizedBox(height: 8),
              Text(
                'What is $_a + $_b?',
                style: TTTypography.displayHero(color: TTColors.darkBrown),
              ),
              if (_hint != null) ...[
                const SizedBox(height: 8),
                Text(_hint!, style: TTTypography.subtitle()),
              ],
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [5, 6, 7, 8, 9].map((n) {
                  final selected = _selected == n;
                  return BounceButton(
                    onPressed: () => _submit(n),
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? TTColors.skySoft
                            : TTColors.creamWhite,
                        borderRadius:
                            BorderRadius.circular(TTSpacing.radiusLg),
                        border: Border.all(
                          color: selected
                              ? TTColors.skyDeep
                              : TTColors.peachDeep,
                          width: 3,
                        ),
                        boxShadow: TTShadows.soft,
                      ),
                      child: Text('$n', style: TTTypography.title()),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
