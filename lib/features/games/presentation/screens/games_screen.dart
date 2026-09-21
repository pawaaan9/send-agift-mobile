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
import '../game_definitions.dart';
import '../game_visuals.dart';
import '../widgets/game_art.dart';
import '../widgets/competition_card.dart';

/// The game zone: every skill game as a colourful tile.
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Game zone')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(competitionsProvider);
          return ref.refresh(gamesListProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.gutter,
                4,
                AppTheme.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _Header()),
            ),
            const SliverToBoxAdapter(child: _CompetitionsStrip()),
            ...games.when<List<Widget>>(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.sports_esports_outlined,
                    title: 'Could not load games',
                    description: '$error',
                    action: FilledButton(
                      onPressed: () => ref.invalidate(gamesListProvider),
                      child: const Text('Try again'),
                    ),
                  ),
                ),
              ],
              data: (items) => items.isEmpty
                  ? const [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.sports_esports_outlined,
                          title: 'No games yet',
                          description:
                              'Skill games will appear here once they open '
                              'in your country.',
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.7,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => FadeSlideIn(
                              delay: Duration(milliseconds: 70 * index),
                              child: _GameTile(game: items[index]),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Play a round', style: AppTypography.display(28)),
        const SizedBox(height: 4),
        Text(
          'Pure-skill games, free to play. Every board comes from a server '
          'seed and every score is replayed on our servers — chance plays no '
          'part.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Live and upcoming competitions, above the games. Stays out of the way
/// when there are none or they cannot be loaded — the games still work.
class _CompetitionsStrip extends ConsumerWidget {
  const _CompetitionsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(competitionsProvider).valueOrNull;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.star),
                const SizedBox(width: 6),
                Text('Competitions', style: AppTypography.display(22)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              2,
              AppTheme.gutter,
              12,
            ),
            child: Text(
              'Pre-funded prizes. Same board for everyone — the best verified '
              'score wins.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => CompetitionCard(
                competition: items[index],
                onTap: () async {
                  await context.push(
                    AppRoutes.competitionPath(items[index].id),
                  );
                  if (context.mounted) ref.invalidate(competitionsProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends ConsumerStatefulWidget {
  const _GameTile({required this.game});

  final Game game;

  @override
  ConsumerState<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends ConsumerState<_GameTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final visual = GameVisual.of(game.slug);
    final best = ref.watch(leaderboardProvider(game.slug)).valueOrNull?.myBest;

    return PressableScale(
      onTap: () {
        // The server can offer a game before this build of the app knows
        // how to run it; say so rather than silently doing nothing.
        if (!gameDefinitions.containsKey(game.slug)) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${game.name} needs the latest version of the app.',
                ),
              ),
            );
          return;
        }
        context.push(AppRoutes.gamePath(game.slug));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: visual.colors,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: visual.colors[1].withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                bottom: -22,
                child: GameArt(
                  slug: game.slug,
                  size: 130,
                  accent: Colors.white,
                  opacity: 0.16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _float,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          -4 + 8 * Curves.easeInOut.transform(_float.value),
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: GameArt(slug: game.slug, size: 38),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(20, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visual.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              best != null && best > 0 ? 'Best $best' : 'New',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: visual.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Leaderboard',
                  onPressed: () =>
                      context.push(AppRoutes.gameLeaderboardPath(game.slug)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                  ),
                  icon: const Icon(
                    Icons.leaderboard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
