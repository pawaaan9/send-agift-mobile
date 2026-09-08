import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/catalog_providers.dart';
import '../domain/reel.dart';

/// The reels feed, built from the live catalog.
///
/// Gifts with a real photo and a description make the strongest clips, so
/// those lead; the rest follow so a thin catalog still fills the feed. An
/// empty catalog stays empty — the screen says so rather than inventing
/// content.
final reelsProvider = Provider<AsyncValue<List<Reel>>>((ref) {
  return ref.watch(catalogProvider).whenData((gifts) {
    final featured = <Reel>[];
    final rest = <Reel>[];

    for (final gift in gifts) {
      final reel = Reel.fromGift(gift);
      if (gift.description.trim().isNotEmpty) {
        featured.add(reel);
      } else {
        rest.add(reel);
      }
    }

    return [...featured, ...rest];
  });
});

/// Reels the viewer has liked, this session. Likes are a lightweight signal
/// separate from saving the gift — the heart on a reel is about the clip, the
/// bookmark still goes to the wishlist.
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
