import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../messages/data/messages_providers.dart';
import '../../../products/data/catalog_providers.dart';
import '../../../reviews/data/reviews_repository.dart';
import '../../../reviews/domain/product_review.dart';
import '../../../reviews/presentation/screens/write_review_screen.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../data/orders_repository.dart';
import '../../domain/customer_order.dart';
import 'order_list_screen.dart';

/// One order and its gifts. Each gift comes from one shop, so this is where a
/// customer messages that shop about their item — a delivery question, a
/// change, or photos of a gift that arrived damaged.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(customerOrderProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(order.valueOrNull?.orderNumber ?? 'Order')),
      body: SafeArea(
        child: order.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => EmptyState(
            icon: Icons.receipt_long_outlined,
            title: "Couldn't load this order",
            description: error.toString(),
            action: OutlinedButton(
              onPressed: () => ref.invalidate(customerOrderProvider(orderId)),
              child: const Text('Try again'),
            ),
          ),
          data: (order) => FadeSlideIn(child: _OrderBody(order: order)),
        ),
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final delivery = order.deliveryDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        32,
      ),
      children: [
        AppPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: AppTypography.display(22),
                    ),
                  ),
                  OrderStatusChip(order: order),
                ],
              ),
              const SizedBox(height: 14),
              _Fact(
                label: 'Placed',
                value: DateFormat.yMMMd().format(order.createdAt.toLocal()),
              ),
              if (delivery != null)
                _Fact(
                  label: 'Delivery',
                  value: DateFormat.yMMMEd().format(delivery.toLocal()),
                ),
              const Divider(height: 22),
              _Fact(label: 'Total', value: order.totalLabel, emphasis: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('GIFTS IN THIS ORDER', style: AppTypography.eyebrow),
        ),
        for (final item in order.items) ...[
          _OrderItemCard(order: order, item: item),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        AppPanel(
          color: AppColors.cream,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 19,
                color: AppColors.purple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Something wrong with a gift? Message its shop and attach '
                  'photos — they reply in Messages.',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: emphasis ? textTheme.titleMedium : textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends ConsumerWidget {
  const _OrderItemCard({required this.order, required this.item});

  final CustomerOrder order;
  final CustomerOrderItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gift = ref.watch(giftByIdProvider(item.productId)).valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    // Unread replies from this item's shop, if there's already a thread.
    final thread = (ref.watch(inboxProvider).valueOrNull ?? const [])
        .where(
          (conversation) =>
              conversation.type == 'order' &&
              conversation.orderItemId == item.id,
        )
        .firstOrNull;
    final unread = thread?.unreadCount ?? 0;

    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: gift == null
                      ? Container(
                          color: AppColors.muted,
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.mutedForeground,
                          ),
                        )
                      : AppNetworkImage(url: gift.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift?.name ?? 'Gift',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    if (gift?.shopName != null)
                      Text(
                        gift!.shopName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty ${item.quantity} · ${order.formatAmount(item.unitAmount)} · '
                      '${item.fulfilmentLabel}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(
              thread != null
                  ? AppRoutes.chatPath(thread.id)
                  : AppRoutes.askAboutOrderItemPath(
                      item.id,
                      productId: item.productId,
                    ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: Text(
              unread > 0
                  ? '$unread new ${unread == 1 ? 'reply' : 'replies'} from the shop'
                  : thread != null
                  ? 'Open chat with the shop'
                  : 'Message the shop',
            ),
          ),
          _ReviewAction(item: item, giftName: gift?.name),
        ],
      ),
    );
  }
}

/// Writes or reopens this line's review. Hidden until the line is delivered,
/// because the API refuses a review before then.
class _ReviewAction extends ConsumerWidget {
  const _ReviewAction({required this.item, this.giftName});

  final CustomerOrderItem item;
  final String? giftName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.fulfilmentStatus != 'delivered') return const SizedBox.shrink();

    // One request for the whole screen rather than one per line.
    final mine = ref.watch(myReviewsByOrderItemProvider(null)).valueOrNull;
    final existing = mine?[item.id];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: existing == null
          ? FilledButton.tonalIcon(
              onPressed: () => _open(context, ref, null),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Write a review'),
            )
          : OutlinedButton.icon(
              onPressed: () => _open(context, ref, existing),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarMeter(value: existing.rating.toDouble(), size: 13),
                  const SizedBox(width: 8),
                  const Text('Edit your review'),
                ],
              ),
            ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ProductReview? existing,
  ) async {
    await Navigator.of(context).push<ProductReview>(
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          orderItemId: item.id,
          existing: existing,
          productName: giftName,
        ),
      ),
    );
    ref.invalidate(myReviewsProvider);
  }
}
