import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/reviews_repository.dart';
import '../../domain/product_review.dart';
import '../widgets/review_card.dart';
import 'write_review_screen.dart';

/// Everything the signed-in customer has written, newest first, with a way to
/// edit or take one down.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My reviews')),
      body: SafeArea(
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              error is AppException ? error.message : 'Could not load reviews.',
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'No reviews yet',
                  description:
                      'Once a gift is delivered you can review it from the '
                      'order — your rating helps the next person choose.',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myReviewsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.gutter),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final review = items[index];
                  return ReviewCard(
                    review: review,
                    onEdit: () => _edit(context, ref, review),
                    onDelete: () => _confirmDelete(context, ref, review),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProductReview review,
  ) async {
    await Navigator.of(context).push<ProductReview>(
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          orderItemId: review.orderItemId,
          existing: review,
        ),
      ),
    );
    ref.invalidate(myReviewsProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductReview review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this review?'),
        content: const Text(
          'It will be removed from the gift straight away. You can write a '
          'new one for the same order later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.destructive,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reviewsRepositoryProvider).delete(review.id);
      ref.invalidate(myReviewsProvider);
      ref.invalidate(productReviewsProvider(review.productId));
      ref.invalidate(productReviewSummaryProvider(review.productId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
