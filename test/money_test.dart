import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/core/utils/money.dart';

void main() {
  group('Money.format', () {
    test('keeps a unique symbol', () {
      expect(Money.format(2500, 'GBP'), '£25.00');
      expect(Money.format(2500, 'EUR'), '€25.00');
    });

    test('disambiguates currencies that share the dollar sign', () {
      // A bare "$25.00" would leave an AUD price indistinguishable from USD.
      expect(Money.format(2500, 'AUD'), 'AUD 25.00');
      expect(Money.format(2500, 'USD'), 'USD 25.00');
      expect(Money.format(2500, 'NZD'), 'NZD 25.00');
    });

    test('respects zero-decimal currencies', () {
      expect(Money.format(2500, 'JPY'), 'JPY 2,500');
    });

    test('scales minor units by the currency fraction digits', () {
      expect(Money.minorToMajor(2500, 'AUD'), 25.0);
      expect(Money.minorToMajor(2500, 'JPY'), 2500.0);
      expect(Money.majorToMinor(25, 'AUD'), 2500);
    });

    test('falls back readably for an unknown code', () {
      expect(Money.format(2500, 'ZZZ'), contains('ZZZ'));
    });
  });
}
