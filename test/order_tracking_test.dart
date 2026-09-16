import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/orders/domain/customer_order.dart';

void main() {
  test('an order line without a shipment has no tracking', () {
    final item = CustomerOrderItem.fromJson({
      'id': 'oi1',
      'product_id': 'p1',
      'fulfilment_status': 'accepted',
    });
    expect(item.tracking, isNull);
  });

  test('a shipped line carries the carrier and number', () {
    final item = CustomerOrderItem.fromJson({
      'id': 'oi1',
      'product_id': 'p1',
      'fulfilment_status': 'dispatched',
      'tracking': {
        'courier_provider': 'USPS',
        'tracking_number': '9334620845500001483410',
        'tracking_url': 'https://tools.usps.com/go/TrackConfirmAction',
        'status': 'in_transit',
        'delivery_mode': 'courier',
        'shipped_at': '2026-09-16T07:30:00Z',
      },
    });

    final tracking = item.tracking!;
    expect(tracking.courierProvider, 'USPS');
    expect(tracking.trackingNumber, '9334620845500001483410');
    expect(tracking.isDelivered, isFalse);
    expect(tracking.isSellerManaged, isFalse);
    expect(tracking.shippedAt, isNotNull);
    // Never a raw enum on screen.
    expect(tracking.label, 'On its way');
  });

  test('a seller-arranged shipment is flagged, even with no tracking link', () {
    final item = CustomerOrderItem.fromJson({
      'tracking': {
        'courier_provider': 'Kandy Express',
        'tracking_number': 'KEC-00123',
        'status': 'in_transit',
        'delivery_mode': 'seller_managed',
        'shipped_at': '2026-09-16T07:30:00Z',
      },
    });
    final tracking = item.tracking!;
    expect(tracking.isSellerManaged, isTrue);
    expect(tracking.trackingUrl, isNull);
  });

  test('every shipment status reads as plain English', () {
    for (final status in [
      'label_created',
      'collected',
      'in_transit',
      'delivered',
      'failed',
      'returned',
      'something_new',
    ]) {
      final tracking = OrderItemTracking.fromJson({
        'status': status,
        'delivery_mode': 'courier',
      });
      expect(tracking.label, isNotEmpty);
      expect(tracking.label, isNot(contains('_')));
      expect(tracking.hint, isNotEmpty);
    }
  });

  test('delivered is recognised', () {
    final tracking = OrderItemTracking.fromJson({
      'status': 'delivered',
      'delivery_mode': 'courier',
      'delivered_at': '2026-09-18T10:00:00Z',
    });
    expect(tracking.isDelivered, isTrue);
    expect(tracking.deliveredAt, isNotNull);
    expect(tracking.label, 'Delivered');
  });
}
