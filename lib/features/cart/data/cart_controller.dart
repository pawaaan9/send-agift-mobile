import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/catalog_providers.dart';
import '../domain/cart_item.dart';
import 'cart_storage.dart';

final cartStorageProvider = Provider<CartStorage>((ref) => CartStorage());

/// Guest-first cart. Items live on the device until checkout, so browsing and
/// building a cart never require an account.
class CartController extends StateNotifier<List<CartItem>> {
  CartController(this._storage) : super(const []) {
    _restore();
  }

  final CartStorage _storage;

  Future<void> _restore() async {
    state = await _storage.read();
  }

  void add(String giftId, {int quantity = 1}) {
    final existing = state.where((item) => item.giftId == giftId).toList();
    if (existing.isEmpty) {
      _persist([...state, CartItem(giftId: giftId, quantity: quantity)]);
      return;
    }
    setQuantity(giftId, existing.first.quantity + quantity);
  }

  void setQuantity(String giftId, int quantity) {
    if (quantity <= 0) {
      remove(giftId);
      return;
    }
    _persist([
      for (final item in state)
        if (item.giftId == giftId) item.copyWith(quantity: quantity) else item,
    ]);
  }

  void remove(String giftId) {
    _persist(state.where((item) => item.giftId != giftId).toList());
  }

  void clear() => _persist(const []);

  bool contains(String giftId) => state.any((item) => item.giftId == giftId);

  void _persist(List<CartItem> next) {
    state = next;
    _storage.write(next);
  }
}

final cartProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
  return CartController(ref.watch(cartStorageProvider));
});

/// Total number of units in the cart — drives the bottom-nav badge.
final cartCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartProvider)
      .fold<int>(0, (total, item) => total + item.quantity);
});

/// Cart entries joined with their catalog gifts. Items whose gift is no longer
/// published simply drop out of the list.
final cartLinesProvider = Provider<AsyncValue<List<CartLine>>>((ref) {
  final items = ref.watch(cartProvider);
  final catalog = ref.watch(catalogProvider);

  return catalog.whenData((gifts) {
    final byId = {for (final gift in gifts) gift.id: gift};
    return [
      for (final item in items)
        if (byId[item.giftId] case final gift?)
          CartLine(gift: gift, quantity: item.quantity),
    ];
  });
});

/// Cart money summary in minor units, using the first line's currency.
class CartSummary {
  const CartSummary({
    required this.subtotal,
    required this.shipping,
    required this.currency,
  });

  final int subtotal;
  final int shipping;
  final String currency;

  int get total => subtotal + shipping;
}

/// Free shipping over 75.00 in the cart currency, mirroring the web rule.
const int _freeShippingThreshold = 7500;
const int _flatShippingFee = 599;

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final lines = ref.watch(cartLinesProvider).valueOrNull ?? const [];
  if (lines.isEmpty) {
    return const CartSummary(subtotal: 0, shipping: 0, currency: 'USD');
  }

  final subtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotalAmount);
  return CartSummary(
    subtotal: subtotal,
    shipping: subtotal >= _freeShippingThreshold ? 0 : _flatShippingFee,
    currency: lines.first.gift.currency,
  );
});
