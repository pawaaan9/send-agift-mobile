import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../products/data/catalog_providers.dart';
import '../../products/domain/gift.dart';

/// Saved gifts (the wishlist). Kept on device so a guest can collect ideas
/// before ever creating an account; syncing to the server happens at sign-in.
class SavedGiftsController extends StateNotifier<Set<String>> {
  SavedGiftsController() : super(const {}) {
    _restore();
  }

  static const _key = 'saved_gift_ids_v1';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> _persist(Set<String> next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isSaved(String giftId) => state.contains(giftId);

  /// Returns true when the gift ended up saved, so callers can word the toast.
  bool toggle(String giftId) {
    final next = Set<String>.from(state);
    final saved = !next.remove(giftId);
    if (saved) next.add(giftId);
    _persist(next);
    return saved;
  }
}

final savedGiftsProvider =
    StateNotifierProvider<SavedGiftsController, Set<String>>((ref) {
  return SavedGiftsController();
});

/// Saved ids resolved against the catalog, newest-first is not tracked so the
/// order follows the catalog.
final savedGiftListProvider = Provider<AsyncValue<List<Gift>>>((ref) {
  final savedIds = ref.watch(savedGiftsProvider);
  final catalog = ref.watch(catalogProvider);

  return catalog.whenData(
    (gifts) => gifts.where((gift) => savedIds.contains(gift.id)).toList(),
  );
});
