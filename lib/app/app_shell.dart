import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/cart/data/cart_controller.dart';
import '../features/saved/data/saved_controller.dart';

/// Bottom-nav scaffold for the five customer tabs.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final savedCount = ref.watch(savedGiftsProvider).length;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.saved_search_rounded),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: _Badged(
                count: savedCount,
                child: const Icon(Icons.favorite_border_rounded),
              ),
              selectedIcon: _Badged(
                count: savedCount,
                child: const Icon(Icons.favorite_rounded),
              ),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: _Badged(
                count: cartCount,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: _Badged(
                count: cartCount,
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

/// Small count bubble on the saved and cart tabs.
class _Badged extends StatelessWidget {
  const _Badged({required this.child, required this.count});

  final Widget child;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.primary,
      textColor: AppColors.primaryForeground,
      child: child,
    );
  }
}
