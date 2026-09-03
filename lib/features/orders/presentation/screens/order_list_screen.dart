import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/data/auth_controller.dart';

/// Order history. This is the second surface (with checkout) that genuinely
/// needs an account, so guests get a sign-in prompt rather than an empty list.
class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: SafeArea(
        child: auth.isSignedIn
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                description:
                    'Gifts you send will appear here with live delivery '
                    'tracking.',
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.gutter,
                ),
                child: EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to see your orders',
                  description:
                      'Order history and delivery tracking are tied to your '
                      'account. Browsing stays open either way.',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
