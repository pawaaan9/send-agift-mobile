import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Floating pill navigation bar, following the BMS Pro pattern: a rounded
/// card inset from the screen edges, icons only, with an animated dot under
/// the active tab and a subtle scale on selection.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppBottomNavItem> items;

  static const double _barHeight = 72;
  static const double _radius = 24;
  static const double _iconSize = 26;
  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / items.length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Dot that slides to sit under the selected tab.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: (currentIndex * slotWidth) +
                        (slotWidth / 2) -
                        (_dotSize / 2),
                    bottom: 10,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _NavSlot(
                          item: items[i],
                          width: slotWidth,
                          height: _barHeight,
                          selected: i == currentIndex,
                          onTap: () => onChanged(i),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One tab: an icon, an accessibility label, and an optional count badge.
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBottomNav._radius),
          onTap: onTap,
          // Labels are hidden in this design, so the tab still needs to
          // announce itself to screen readers.
          child: Semantics(
            label: item.label,
            button: true,
            selected: selected,
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: selected ? 1.1 : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: AppBottomNav._iconSize,
                      color: selected
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: _CountBadge(count: item.badgeCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.primaryForeground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
