import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../domain/reel.dart';
import 'reels_repository.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  return ReelsRepository(ref.watch(apiClientProvider));
});

/// The reel feed as the screen sees it: the reels loaded so far, plus whether
/// there is another page behind them.
class ReelFeedState {
  const ReelFeedState({
    this.reels = const [],
    this.cursor,
    this.loadingMore = false,
  });

  final List<Reel> reels;
  final String? cursor;
  final bool loadingMore;

  bool get hasMore => cursor != null && cursor!.isNotEmpty;

  ReelFeedState copyWith({
    List<Reel>? reels,
    String? cursor,
    bool? loadingMore,
  }) {
    return ReelFeedState(
      reels: reels ?? this.reels,
      cursor: cursor,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Loads the first page of the feed, then appends the next one as the viewer
/// nears the end — the feed should never dead-end while the API still has
/// reels to give.
class ReelFeedController extends StateNotifier<AsyncValue<ReelFeedState>> {
  ReelFeedController(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final ReelsRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final page = await _repository.loadFeed();
      state = AsyncValue.data(
        ReelFeedState(reels: page.reels, cursor: page.nextCursor),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncValue.data(current.copyWith(
      cursor: current.cursor,
      loadingMore: true,
    ));

    try {
      final page = await _repository.loadFeed(cursor: current.cursor);
      state = AsyncValue.data(
        ReelFeedState(
          reels: [...current.reels, ...page.reels],
          cursor: page.nextCursor,
        ),
      );
    } catch (_) {
      // Keep what is already on screen; the next scroll can try again.
      state = AsyncValue.data(current.copyWith(
        cursor: current.cursor,
        loadingMore: false,
      ));
    }
  }
}

final reelFeedProvider =
    StateNotifierProvider<ReelFeedController, AsyncValue<ReelFeedState>>((ref) {
  return ReelFeedController(ref.watch(reelsRepositoryProvider));
});

/// Reels the viewer has liked, this session. A like is about the clip; saving
/// the gift itself still goes through the wishlist.
class ReelLikesController extends StateNotifier<Set<String>> {
  ReelLikesController() : super(const {});

  /// Returns true when the reel ended up liked.
  bool toggle(String reelId) {
    final next = Set<String>.from(state);
    final liked = !next.remove(reelId);
    if (liked) next.add(reelId);
    state = next;
    return liked;
  }
}

final reelLikesProvider =
    StateNotifierProvider<ReelLikesController, Set<String>>((ref) {
  return ReelLikesController();
});
