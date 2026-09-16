import '../../../core/utils/money.dart';

/// What a customer may see of a shipment: who is carrying the parcel and how
/// to follow it. The label, provider ids and customs paperwork stay with the
/// seller.
class OrderItemTracking {
  const OrderItemTracking({
    required this.status,
    required this.deliveryMode,
    this.courierProvider,
    this.trackingNumber,
    this.trackingUrl,
    this.deliveredAt,
    this.shippedAt,
  });

  /// label_created | collected | in_transit | delivered | failed | returned.
  final String status;

  /// `courier` for a bought carrier label, `seller_managed` when the shop
  /// arranged delivery itself.
  final String deliveryMode;
  final String? courierProvider;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? deliveredAt;
  final DateTime? shippedAt;

  bool get isDelivered => status == 'delivered';
  bool get isSellerManaged => deliveryMode == 'seller_managed';

  /// Plain English, so a raw enum never reaches the screen.
  String get label => switch (status) {
    'label_created' => 'Ready to collect',
    'collected' => 'Picked up',
    'in_transit' => 'On its way',
    'delivered' => 'Delivered',
    'failed' => 'Delivery problem',
    'returned' => 'Returned to sender',
    _ => 'Shipped',
  };

  String get hint => switch (status) {
    'label_created' =>
      'The shop has printed the label. The courier collects it next.',
    'collected' => 'The courier has the parcel.',
    'in_transit' => 'The parcel is moving through the courier network.',
    'delivered' => 'The courier marked this parcel as delivered.',
    'failed' => 'The courier could not complete delivery. Message the shop.',
    'returned' => 'The parcel is on its way back to the shop.',
    _ => 'This parcel is on its way.',
  };

  factory OrderItemTracking.fromJson(Map<String, dynamic> json) {
    return OrderItemTracking(
      status: json['status'] as String? ?? '',
      deliveryMode: json['delivery_mode'] as String? ?? 'courier',
      courierProvider: json['courier_provider'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
      shippedAt: DateTime.tryParse(json['shipped_at'] as String? ?? ''),
    );
  }
}

/// One line of an order — a gift from one shop. Its [id] is the
/// `order_item_id` an order chat with that shop is about.
class CustomerOrderItem {
  const CustomerOrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitAmount,
    required this.totalAmount,
    required this.fulfilmentStatus,
    this.tracking,
  });

  final String id;
  final String productId;
  final int quantity;
  final int unitAmount;
  final int totalAmount;
  final String fulfilmentStatus;

  /// Present once the line has shipped.
  final OrderItemTracking? tracking;

  String get fulfilmentLabel =>
      _fulfilmentLabels[fulfilmentStatus] ?? _humanize(fulfilmentStatus);

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    final rawTracking = json['tracking'];
    return CustomerOrderItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitAmount: (json['unit_amount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      fulfilmentStatus: json['fulfilment_status'] as String? ?? 'pending',
      tracking: rawTracking is Map<String, dynamic>
          ? OrderItemTracking.fromJson(rawTracking)
          : null,
    );
  }
}

/// A customer's order, from `GET /customers/me/orders`. Items are only
/// present on the single-order response.
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    this.deliveryDate,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String status;
  final int totalAmount;
  final String currency;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final List<CustomerOrderItem> items;

  String get statusLabel => _orderStatusLabels[status] ?? _humanize(status);
  String get totalLabel => Money.format(totalAmount, currency);
  String formatAmount(int minorAmount) => Money.format(minorAmount, currency);

  bool get isClosed =>
      status == 'delivered' || status == 'cancelled' || status == 'refunded';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? 'Order',
      status: json['status'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      deliveryDate: DateTime.tryParse(json['delivery_date'] as String? ?? ''),
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CustomerOrderItem.fromJson)
              .toList(growable: false) ??
          const <CustomerOrderItem>[],
    );
  }
}

const _orderStatusLabels = {
  'draft': 'Draft',
  'pending_payment': 'Awaiting payment',
  'paid': 'Paid',
  'accepted': 'Accepted',
  'preparing': 'Being prepared',
  'dispatched': 'On its way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'refunded': 'Refunded',
};

const _fulfilmentLabels = {
  'pending': 'Waiting for the shop',
  'accepted': 'Accepted by the shop',
  'preparing': 'Being prepared',
  'ready': 'Ready to ship',
  'dispatched': 'On its way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

String _humanize(String value) {
  if (value.isEmpty) return 'Unknown';
  final spaced = value.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}
