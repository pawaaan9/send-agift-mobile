import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../features/saved/data/saved_controller.dart';

/// Scaffold for the five customer tabs, using the floating pill nav bar.
///
/// Reels sits in the middle as the raised button — it is the most-swiped
/// surface once someone is browsing, so it gets the spot the thumb reaches
/// first.
///
/// Cart isn't a tab: it opens as a right-side panel over whatever tab is
/// showing (from the home top bar, or a "View cart" prompt), so it never
/// needs its own place in the stack.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCount = ref.watch(savedGiftsProvider).length;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onChanged: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const AppBottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          const AppBottomNavItem(icon: Icons.search_rounded, label: 'Explore'),
          const AppBottomNavItem(
            icon: Icons.movie_filter_rounded,
            label: 'Reels',
            orb: true,
          ),
          AppBottomNavItem(
            icon: Icons.favorite_rounded,
            label: 'Saved',
            badgeCount: savedCount,
          ),
          const AppBottomNavItem(icon: Icons.person_rounded, label: 'Account'),
        ],
      ),
    );
  }
}
