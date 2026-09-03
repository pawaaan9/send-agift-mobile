import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cart_item.dart';

/// Persists the guest cart on device. Carts survive app restarts and are only
/// exchanged for a server-side order at checkout, when the customer signs in.
class CartStorage {
  static const _key = 'cart_items_v1';

  Future<List<CartItem>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .where((item) => item.giftId.isNotEmpty && item.quantity > 0)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> write(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
