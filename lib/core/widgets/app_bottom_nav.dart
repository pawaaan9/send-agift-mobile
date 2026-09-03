import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Floating pill navigation bar. A gradient capsule glides between tabs —
/// box-navy into ribbon-violet, the app's signature pairing — carrying the
/// active icon in white while the rest sit quiet in muted ink.
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

  static const double _barHeight = 68;
  static const double _barRadius = 28;
  static const double _pillRadius = 20;
  static const double _iconSize = 24;
  static const Duration _slideDuration = Duration(milliseconds: 380);
  static const Curve _slideCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: _barHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_barRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / items.length;
              final pillWidth = slotWidth - 14;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // The active tab's backdrop, gliding from slot to slot.
                  AnimatedPositioned(
                    duration: _slideDuration,
                    curve: _slideCurve,
                    left: (currentIndex * slotWidth) + (slotWidth - pillWidth) / 2,
                    top: 8,
                    bottom: 8,
                    width: pillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.brandGradient,
                        ),
                        borderRadius: BorderRadius.circular(_pillRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _NavSlot(
                          item: items[i],
                          width: slotWidth,
                          selected: i == currentIndex,
                          onTap: () {
                            if (i != currentIndex) {
                              HapticFeedback.selectionClick();
                            }
                            onChanged(i);
                          },
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
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBottomNav._pillRadius),
          onTap: onTap,
          // Labels are hidden in this design, so the tab still needs to
          // announce itself to screen readers.
          child: Semantics(
            label: item.label,
            button: true,
            selected: selected,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: selected ? 0 : 1, end: selected ? 1 : 0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) {
                  return Transform.scale(
                    // A touch of overshoot on the way in reads as a small
                    // bounce rather than a mechanical snap.
                    scale: 1 + (0.16 * _overshoot(t)),
                    child: child,
                  );
                },
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: selected
                        ? AppColors.mutedForeground
                        : AppColors.primaryForeground,
                    end: selected
                        ? AppColors.primaryForeground
                        : AppColors.mutedForeground,
                  ),
                  duration: const Duration(milliseconds: 220),
                  builder: (context, color, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item.icon,
                        size: AppBottomNav._iconSize,
                        color: color,
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
      ),
    );
  }

  /// Cheap ease-out-back approximation so the icon settles in with a hint of
  /// spring rather than linearly scaling to size.
  static double _overshoot(double t) {
    const c = 1.7;
    final shifted = t - 1;
    return shifted * shifted * ((c + 1) * shifted + c) + 1;
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
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.tealForeground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
