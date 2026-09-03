import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../domain/gift.dart';
import 'catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

/// The full marketplace catalog, shared by home, explore and detail screens.
final catalogProvider = FutureProvider<List<Gift>>((ref) {
  return ref.watch(catalogRepositoryProvider).loadCatalog();
});

/// Looks a gift up in the loaded catalog — detail screens are opened from a
/// list, so the item is already in memory in the normal case.
final giftByIdProvider = FutureProvider.family<Gift?, String>((ref, id) async {
  final catalog = await ref.watch(catalogProvider.future);
  for (final gift in catalog) {
    if (gift.id == id) return gift;
  }
  return null;
});

/// Active search text on the explore screen.
final exploreQueryProvider = StateProvider<String>((ref) => '');

/// Active category filter on the explore screen; `all` means unfiltered.
final exploreCategoryProvider = StateProvider<String>((ref) => 'all');

/// Catalog narrowed by the current query and category filters.
final filteredGiftsProvider = Provider<AsyncValue<List<Gift>>>((ref) {
  final catalog = ref.watch(catalogProvider);
  final query = ref.watch(exploreQueryProvider);
  final category = ref.watch(exploreCategoryProvider);

  return catalog.whenData((gifts) {
    return gifts.where((gift) {
      final matchesCategory = category == 'all' || gift.categoryId == category;
      return matchesCategory && gift.matchesQuery(query);
    }).toList(growable: false);
  });
});
