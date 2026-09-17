import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../auth/data/auth_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/checkout.dart';

/// Recipients, delivery pricing and order placement.
class CheckoutRepository {
  CheckoutRepository(this._client);

  final ApiClient _client;

  /// Saved recipients. Names only — addresses come from [getRecipient].
  Future<List<Recipient>> listRecipients() async {
    try {
      final response = await _client.dio.get<dynamic>('/customers/me/recipients');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Recipient.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  /// One recipient with their addresses.
  Future<Recipient> getRecipient(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/customers/me/recipients/$id',
      );
      return Recipient.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  /// Prices delivery before the order exists. The server picks the cheapest
  /// service that still arrives by [deliveryDate].
  Future<DeliveryQuote> quoteDelivery({
    required String recipientId,
    required DateTime deliveryDate,
    required List<CartLine> lines,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/customers/me/shipping/quote',
        data: {
          'recipient_id': recipientId,
          'delivery_date': _dateOnly(deliveryDate),
          'items': [
            for (final line in lines)
              {'product_id': line.gift.id, 'quantity': line.quantity},
          ],
        },
      );
      return DeliveryQuote.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  /// Places the order. [deliveryAmount] is only sent when it was quoted in the
  /// cart's own currency — the order stores a bare integer, so a quote in a
  /// different currency would be saved as the wrong amount.
  Future<String> placeOrder({
    required String countryId,
    required DateTime deliveryDate,
    required List<CartLine> lines,
    String? recipientId,
    String? giftMessage,
    int? deliveryAmount,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/customers/me/orders',
        data: {
          'country_id': countryId,
          'customer_type': 'personal',
          'delivery_date': _dateOnly(deliveryDate),
          'recipient_id': ?recipientId,
          if (giftMessage != null && giftMessage.trim().isNotEmpty)
            'gift_message': giftMessage.trim(),
          'delivery_amount': ?deliveryAmount,
          'items': [
            for (final line in lines)
              {'product_id': line.gift.id, 'quantity': line.quantity},
          ],
        },
      );
      return response.data?['id'] as String? ?? '';
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  /// The customer's own country, used as the order's country when a recipient
  /// address does not supply one.
  Future<String> myCountryId() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>('/customers/me');
      return response.data?['country_id'] as String? ?? '';
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider));
});

final recipientsProvider = FutureProvider.autoDispose<List<Recipient>>((ref) async {
  final signedIn = ref.watch(authProvider.select((auth) => auth.isSignedIn));
  if (!signedIn) return const [];
  return ref.watch(checkoutRepositoryProvider).listRecipients();
});

/// One recipient with addresses, fetched once someone is actually picked.
final recipientDetailsProvider = FutureProvider.autoDispose
    .family<Recipient, String>((ref, id) {
      return ref.watch(checkoutRepositoryProvider).getRecipient(id);
    });
