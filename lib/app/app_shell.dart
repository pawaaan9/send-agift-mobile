import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../features/saved/data/saved_controller.dart';

/// Scaffold for the four customer tabs, using the floating pill nav bar.
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
