import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../products/data/catalog_providers.dart';
import '../../../products/domain/gift.dart';
import '../../../products/presentation/widgets/gift_card.dart';
import '../widgets/category_strip.dart';
import '../widgets/feature_bar.dart';
import '../widgets/home_hero.dart';
import '../widgets/offer_banner.dart';
import '../widgets/testimonial_carousel.dart';

/// Storefront landing screen. Opens with no sign-in, exactly like the web.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(catalogProvider);
            await ref.read(catalogProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _HomeTopBar(),
              const HomeHero(),
              const FeatureBar(),
              const SizedBox(height: 34),
              SectionHeading(
                title: 'Shop by occasion',
                actionLabel: 'View all',
                onAction: () => context.go(AppRoutes.explore),
              ),
              const CategoryStrip(),
              const SizedBox(height: 34),
              SectionHeading(
                title: 'Fresh from our shops',
                subtitle: 'Published gifts, ready to send.',
                actionLabel: 'View all',
                onAction: () => context.go(AppRoutes.explore),
              ),
              _GiftShelf(catalog: catalog),
              const SizedBox(height: 34),
              const OfferBanner(),
              const SizedBox(height: 34),
              const SectionHeading(title: 'What our customers say'),
              const TestimonialCarousel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 18,
                  color: AppColors.primaryForeground,
                ),
              ),
              const SizedBox(width: 9),
              Text('SendAgift', style: AppTypography.display(20)),
              const Spacer(),
              IconButton(
                onPressed: () => context.push(AppRoutes.orders),
                icon: const Icon(Icons.receipt_long_outlined),
                color: AppColors.foreground,
                tooltip: 'Orders',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Read-only: tapping hands off to Explore, which owns the query.
          AppSearchField(
            readOnly: true,
            onTap: () => context.go(AppRoutes.explore),
          ),
        ],
      ),
    );
  }
}

/// Horizontal shelf of the newest published gifts.
class _GiftShelf extends StatelessWidget {
  const _GiftShelf({required this.catalog});

  final AsyncValue<List<Gift>> catalog;

  @override
  Widget build(BuildContext context) {
    return catalog.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        child: Text(
          "We couldn't load gifts just now. Pull to refresh.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      data: (gifts) {
        if (gifts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Text(
              'No gifts published yet. Shops publish from the seller portal, '
              'and they show up here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        const cardWidth = 176.0;
        final shelf = gifts.take(6).toList();

        return SizedBox(
          // Same square-photo + text-block sizing the grid uses, so the shelf
          // never clips its cards either.
          height: cardWidth + GiftCard.textBlockHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            itemCount: shelf.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: GiftCard(gift: shelf[index]),
            ),
          ),
        );
      },
    );
  }
}
