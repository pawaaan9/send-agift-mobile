import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../data/games_providers.dart';
import '../../domain/game.dart';

/// The game collection: every skill game the platform currently offers.
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(gamesListProvider.future),
          child: games.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: 'Could not load games',
                  description: '$error',
                  action: FilledButton(
                    onPressed: () => ref.invalidate(gamesListProvider),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.sports_esports_outlined,
                      title: 'No games yet',
                      description:
                          'Skill games will appear here once they open in '
                          'your country.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppTheme.gutter),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return const _Intro();
                  final game = items[index - 1];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 40 * index),
                    child: _GameCard(game: game),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Play a round', style: AppTypography.display(28)),
          const SizedBox(height: 4),
          Text(
            'Pure-skill games. No chance, no entry fee — every score is '
            'checked on our servers.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => context.push(AppRoutes.gamePath(game.slug)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name, style: AppTypography.display(19)),
                  if (game.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      game.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
