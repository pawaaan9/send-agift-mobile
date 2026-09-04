import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../products/presentation/widgets/gift_grid.dart';
import '../../data/saved_controller.dart';

/// Wishlist. Works for guests — the list lives on the device and syncs once
/// there is an account.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedGiftListProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    10,
                    AppTheme.gutter,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved gifts', style: AppTypography.display(28)),
                      const SizedBox(height: 4),
                      Text(
                        saved.isEmpty
                            ? 'Tap the heart on any gift to keep it here.'
                            : '${saved.length} gift${saved.length == 1 ? '' : 's'} '
                                'saved on this device.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (saved.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Nothing saved yet',
                    description:
                        'Collect gift ideas as you browse — no account '
                        'needed. Sign in later to keep them across devices.',
                    action: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.explore),
                      child: const Text('Find gifts'),
                    ),
                  ),
                ),
              )
            else ...[
              GiftGrid(gifts: saved, sliver: true, heroPrefix: 'saved'),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ],
        ),
      ),
    );
  }
}
