import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/product_review.dart';
import 'star_rating.dart';

/// The headline above a product's reviews: the average, the distribution
/// behind it, and the three sub-scores.
class ReviewSummaryPanel extends StatelessWidget {
  const ReviewSummaryPanel({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.avgRating.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  StarMeter(value: summary.avgRating, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.reviewCount} '
                    '${summary.reviewCount == 1 ? 'review' : 'reviews'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: RatingBars(
                  breakdown: summary.breakdown,
                  total: summary.reviewCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SubScore(label: 'Quality', value: summary.avgQuality),
              const SizedBox(width: 8),
              _SubScore(label: 'Delivery', value: summary.avgShipping),
              const SizedBox(width: 8),
              _SubScore(label: 'Service', value: summary.avgService),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubScore extends StatelessWidget {
  const _SubScore({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(1),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
