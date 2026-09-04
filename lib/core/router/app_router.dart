import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/products/presentation/screens/explore_screen.dart';
import '../../features/products/presentation/screens/gift_detail_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/saved/presentation/screens/saved_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Tabs
  static const home = '/';
  static const explore = '/explore';
  static const saved = '/saved';
  static const account = '/account';

  // Pushed screens
  static const gift = '/gift';
  // Not a tab: opens as a right-side panel over whatever's on screen.
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const login = '/login';
  static const register = '/register';

  /// The hero tag travels with the route so the detail screen animates from
  /// whichever surface the card was tapped on.
  static String giftDetailPath(String id, {String? heroTag}) {
    if (heroTag == null) return '$gift/$id';
    return '$gift/$id?hero=${Uri.encodeComponent(heroTag)}';
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Fade-and-rise transition for every pushed (non-tab) route, so moving
/// deeper into the app — a gift, checkout, sign-in — feels like a step
/// forward rather than the platform's default hard slide.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Slide-in panel from the right, dimming (rather than replacing) whatever
/// tab is behind it — the cart is a quick check, not a new destination.
CustomTransitionPage<void> _rightSheetPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    barrierLabel: 'Close',
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.8,
          heightFactor: 1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: Material(
              elevation: 16,
              shadowColor: Colors.black,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// The app opens straight onto the storefront — browsing, search, cart and
/// saved gifts all work without an account, so there is no auth redirect here.
/// Sign-in is requested only at checkout and for order history.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cart,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _rightSheetPage(state, const CartScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.gift}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(
          state,
          GiftDetailScreen(
            giftId: state.pathParameters['id'] ?? '',
            heroTag: state.uri.queryParameters['hero'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.orders,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(state, const OrderListScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(state, const RegisterScreen()),
      ),
    ],
  );
});
