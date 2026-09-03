import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../features/cart/data/cart_controller.dart';
import '../features/saved/data/saved_controller.dart';

/// Scaffold for the five customer tabs, using the floating pill nav bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
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
          AppBottomNavItem(
            icon: Icons.shopping_bag_rounded,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const AppBottomNavItem(icon: Icons.person_rounded, label: 'Account'),
        ],
      ),
    );
  }
}
