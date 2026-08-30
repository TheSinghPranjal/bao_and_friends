import 'package:flutter/material.dart';

import '../theme/tt_colors.dart';
import '../theme/tt_typography.dart';
import 'bounce_button.dart';

/// One tappable item in a bottom [ItemTrayBar].
class TrayItem {
  const TrayItem({
    required this.label,
    required this.icon,
    required this.accent,
    required this.done,
    this.onTap,
    this.imageAsset,
    this.badgeCount = 0,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool done;
  final VoidCallback? onTap;

  /// Optional 3D illustration; falls back to [icon] when null.
  final String? imageAsset;

  /// Due / missed count badge (e.g. Play football).
  final int badgeCount;

  /// Glow / emphasize when an activity slot is due.
  final bool highlighted;
}

/// Compact bottom tray: 5 icons + labels per page, golden chevrons.
/// Beige pill at 50% opacity — no page dots.
class ItemTrayBar extends StatefulWidget {
  const ItemTrayBar({
    super.key,
    required this.items,
    this.pageSize = 5,
    this.enabled = true,
  });

  final List<TrayItem> items;
  final int pageSize;
  final bool enabled;

  @override
  State<ItemTrayBar> createState() => _ItemTrayBarState();
}

class _ItemTrayBarState extends State<ItemTrayBar> {
  late final PageController _pageController;
  int _page = 0;

  static const _trayBeige = Color(0xFFE8D5B5);

  int get _pageCount {
    if (widget.items.isEmpty) return 1;
    return (widget.items.length / widget.pageSize).ceil();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pageCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + bottomInset),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: _trayBeige.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: TTColors.darkBrown.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        // Chevron | items | chevron — avoids Stack overlay overflow.
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _ChevronButton(
                icon: Icons.chevron_left_rounded,
                enabled: _page > 0,
                onPressed: () => _goTo(_page - 1),
                semanticLabel: 'Previous items',
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * widget.pageSize;
                  final end =
                      (start + widget.pageSize).clamp(0, widget.items.length);
                  final pageItems = widget.items.sublist(start, end);
                  final fillers = widget.pageSize - pageItems.length;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final item in pageItems)
                        Expanded(
                          child: Center(
                            child: _TrayIcon(
                              item: item,
                              // Keep due/highlighted games tappable even if marked done.
                              enabled: widget.enabled &&
                                  (!item.done || item.highlighted || item.badgeCount > 0),
                            ),
                          ),
                        ),
                      for (var i = 0; i < fillers; i++)
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ChevronButton(
                icon: Icons.chevron_right_rounded,
                enabled: _page < _pageCount - 1,
                onPressed: () => _goTo(_page + 1),
                semanticLabel: 'Next items',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: enabled ? onPressed : null,
      enabled: enabled,
      semanticLabel: semanticLabel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE066),
                TTColors.golden,
                Color(0xFFE8B820),
              ],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: TTColors.goldenOutline.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _TrayIcon extends StatelessWidget {
  const _TrayIcon({
    required this.item,
    required this.enabled,
  });

  final TrayItem item;
  final bool enabled;

  static const double _bubble = 44;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: enabled ? item.onTap : null,
      enabled: enabled,
      semanticLabel: item.label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: item.done ? 0.72 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _bubble,
              height: _bubble,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: _bubble,
                    height: _bubble,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.highlighted
                          ? item.accent.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.95),
                      border: Border.all(
                        color: item.highlighted ? item.accent : Colors.white,
                        width: item.highlighted ? 3 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.highlighted
                              ? item.accent.withValues(alpha: 0.45)
                              : TTColors.darkBrown.withValues(alpha: 0.10),
                          blurRadius: item.highlighted ? 10 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: item.imageAsset != null
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                item.imageAsset!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Icon(
                              item.icon,
                              size: 24,
                              color: item.done && !item.highlighted
                                  ? TTColors.bambooDeep
                                  : TTColors.darkBrown.withValues(alpha: 0.88),
                            ),
                    ),
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TTColors.ribbonOrange,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  else if (item.done)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TTColors.bamboo,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TTTypography.caption(color: TTColors.darkBrown).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
