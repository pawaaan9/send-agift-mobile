import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../products/data/catalog_providers.dart';
import '../../../products/domain/gift_category.dart';

/// Horizontally scrolling occasion categories. Tapping one jumps to Explore
/// with that filter already applied.
class CategoryStrip extends ConsumerWidget {
  const CategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        itemCount: GiftCategory.all.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = GiftCategory.all[index];
          final tint =
              AppColors.categoryTints[index % AppColors.categoryTints.length];

          return GestureDetector(
            onTap: () {
              ref.read(exploreCategoryProvider.notifier).state = category.id;
              ref.read(exploreQueryProvider.notifier).state = '';
              context.go(AppRoutes.explore);
            },
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: ClipOval(
                      child: AppNetworkImage(url: category.image),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
