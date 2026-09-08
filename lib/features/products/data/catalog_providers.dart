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

/// Looks a gift up for a detail screen. The loaded catalog answers this in the
/// normal case; a product reached from a reel may not be on it, so the
/// repository falls back to the public product endpoint.
final giftByIdProvider = FutureProvider.family<Gift?, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).giftById(id);
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
