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

  /// Re-reads the current view counts without counting a view.
  ///
  /// The feed lives for as long as the app does, so counts otherwise freeze
  /// at whatever they were when the tab was first opened — and drift away
  /// from what another client (or the website) shows. Listing reels does not
  /// increment anything, so this is safe to call whenever the tab is opened.
  Future<void> refreshViewCounts() async {
    final current = state.valueOrNull;
    if (current == null || current.reels.isEmpty) return;

    try {
      final page = await _repository.loadFeed();
      final counts = {
        for (final reel in page.reels) reel.id: reel.viewCount,
      };

      final latest = state.valueOrNull;
      if (latest == null) return;

      state = AsyncValue.data(
        latest.copyWith(
          reels: [
            for (final reel in latest.reels)
              counts.containsKey(reel.id)
                  ? reel.withViewCount(counts[reel.id]!)
                  : reel,
          ],
          cursor: latest.cursor,
        ),
      );
    } catch (_) {
      // Stale counts are better than an error over something this small.
    }
  }

  /// Records that this reel was watched, and folds the count the API returns
  /// back into the feed so the rail shows the real number.
  Future<void> registerView(String reelId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = await _repository.registerView(reelId);
    if (updated == null) return;

    final latest = state.valueOrNull;
    if (latest == null) return;

    state = AsyncValue.data(
      latest.copyWith(
        reels: [
          for (final reel in latest.reels)
            reel.id == reelId ? reel.withViewCount(updated.viewCount) : reel,
        ],
        cursor: latest.cursor,
      ),
    );
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
