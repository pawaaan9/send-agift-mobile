import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../auth/data/auth_controller.dart';
import '../../data/orders_repository.dart';
import '../../domain/customer_order.dart';

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
        child: FadeSlideIn(
          child: auth.isSignedIn
              ? const _Orders()
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter,
                  ),
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sign in to see your orders',
                    description:
                        'Order history and delivery tracking are tied to '
                        'your account. Browsing stays open either way.',
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
      ),
    );
  }
}

class _Orders extends ConsumerWidget {
  const _Orders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider);

    return orders.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load your orders",
        description: error.toString(),
        action: OutlinedButton(
          onPressed: () => ref.invalidate(customerOrdersProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            description:
                'Gifts you send will appear here with live delivery '
                'tracking.',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(customerOrdersProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              8,
              AppTheme.gutter,
              24,
            ),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _OrderCard(order: list[index]),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final delivery = order.deliveryDate;

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber, style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        delivery == null
                            ? 'Placed ${DateFormat.yMMMd().format(order.createdAt.toLocal())}'
                            : 'Delivery ${DateFormat.yMMMd().format(delivery.toLocal())}',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      OrderStatusChip(order: order),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order.totalLabel, style: textTheme.titleSmall),
                    const SizedBox(height: 18),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedForeground,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Order status as a small pill — teal while it's moving, muted once done.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == 'cancelled' || order.status == 'refunded';
    final background = cancelled
        ? AppColors.destructive.withValues(alpha: 0.1)
        : order.isClosed
        ? AppColors.muted
        : AppColors.accent;
    final foreground = cancelled
        ? AppColors.destructive
        : order.isClosed
        ? AppColors.mutedForeground
        : AppColors.accentForeground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
