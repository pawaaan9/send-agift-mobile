import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/checkout/domain/checkout.dart';

void main() {
  group('DeliveryQuote', () {
    test('reads a complete quote', () {
      final quote = DeliveryQuote.fromJson({
        'shipments': [
          {
            'shop_name': 'PD Gifts',
            'provider': 'USPS',
            'service_name': 'Ground Advantage',
            'amount': 568,
            'currency': 'USD',
            'estimated_days': 2,
            'misses_delivery_date': false,
          },
        ],
        'amount': 568,
        'currency': 'USD',
        'complete': true,
      });

      expect(quote.complete, isTrue);
      expect(quote.amount, 568);
      expect(quote.shipments.single.summary,
          'PD Gifts · USPS Ground Advantage · 2 days');
      expect(quote.missesDeliveryDate, isFalse);
    });

    test('a carrier currency that differs from the cart is never combined', () {
      // The bug this guards: a USD delivery quote added to an AUD cart and
      // labelled AUD.
      final quote = DeliveryQuote.fromJson({
        'amount': 3257,
        'currency': 'USD',
        'complete': true,
        'shipments': [],
      });

      expect(quote.matchesCurrency('AUD'), isFalse);
      expect(quote.matchesCurrency('USD'), isTrue);
      // Case should not decide whether money is added together.
      expect(quote.matchesCurrency('usd'), isTrue);
    });

    test('an incomplete quote carries the reasons', () {
      final quote = DeliveryQuote.fromJson({
        'amount': 0,
        'currency': 'USD',
        'complete': false,
        'unquoted': ['PD Gifts: no carrier available for this route'],
      });
      expect(quote.complete, isFalse);
      expect(quote.unquoted, hasLength(1));
    });

    test('a missed delivery date surfaces from any shipment', () {
      final quote = DeliveryQuote.fromJson({
        'amount': 3257,
        'currency': 'USD',
        'complete': true,
        'shipments': [
          {'amount': 3257, 'currency': 'USD', 'misses_delivery_date': true},
        ],
      });
      expect(quote.missesDeliveryDate, isTrue);
    });
  });

  group('Recipient', () {
    test('delivery address prefers the default one', () {
      final recipient = Recipient.fromJson({
        'id': 'r1',
        'name': 'ABC Kumara',
        'default_address_id': 'a2',
        'addresses': [
          {'id': 'a1', 'line1': 'First St', 'city': 'Kandy'},
          {'id': 'a2', 'line1': '965 Mission St', 'city': 'San Francisco'},
        ],
      });
      expect(recipient.deliveryAddress?.id, 'a2');
    });

    test('falls back to the only address when no default is set', () {
      final recipient = Recipient.fromJson({
        'name': 'ABC Kumara',
        'addresses': [
          {'id': 'a1', 'line1': 'First St', 'city': 'Kandy'},
        ],
      });
      expect(recipient.deliveryAddress?.id, 'a1');
    });

    test('a recipient with no address has none', () {
      final recipient = Recipient.fromJson({'name': 'ABC Kumara'});
      expect(recipient.deliveryAddress, isNull);
    });

    test('formats an address the way a label reads it', () {
      final address = RecipientAddress.fromJson({
        'id': 'a1',
        'line1': '965 Mission St',
        'line2': 'Suite 200',
        'city': 'San Francisco',
        'region': 'CA',
        'postal_code': '94103',
      });
      expect(address.formatted,
          '965 Mission St, Suite 200, San Francisco, CA, 94103');
    });

    test('label includes the relationship only when there is one', () {
      expect(
        Recipient.fromJson({'name': 'ABC', 'relationship': 'Friend'}).label,
        'ABC · Friend',
      );
      expect(Recipient.fromJson({'name': 'ABC'}).label, 'ABC');
    });
  });
}
