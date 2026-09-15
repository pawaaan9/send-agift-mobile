import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../domain/game.dart';
import 'games_repository.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(ref.watch(apiClientProvider));
});

/// The game collection screen.
final gamesListProvider = FutureProvider<List<Game>>((ref) {
  return ref.watch(gamesRepositoryProvider).listGames();
});

/// The board for one game. Invalidated after a score is submitted so a new
/// personal best shows up straight away.
final leaderboardProvider = FutureProvider.family<Leaderboard, String>((
  ref,
  slug,
) {
  return ref.watch(gamesRepositoryProvider).leaderboard(slug);
});
