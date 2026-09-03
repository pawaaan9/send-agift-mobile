import '../../products/domain/gift.dart';

/// A stored cart entry. Only the id and quantity persist; the gift itself is
/// re-resolved from the catalog so prices and availability stay current.
class CartItem {
  const CartItem({required this.giftId, required this.quantity});

  final String giftId;
  final int quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(giftId: giftId, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {'giftId': giftId, 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      giftId: json['giftId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

/// A cart entry joined with its catalog gift, ready to render.
class CartLine {
  const CartLine({required this.gift, required this.quantity});

  final Gift gift;
  final int quantity;

  int get lineTotalAmount => gift.priceAmount * quantity;
}
