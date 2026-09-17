// Checkout models: who a gift goes to, and what delivery will cost.

/// A saved recipient's delivery address.
class RecipientAddress {
  const RecipientAddress({
    required this.id,
    required this.countryId,
    required this.line1,
    required this.city,
    this.line2,
    this.region,
    this.postalCode,
  });

  final String id;
  final String countryId;
  final String line1;
  final String city;
  final String? line2;
  final String? region;
  final String? postalCode;

  /// One line, the way a label would read it.
  String get formatted => [
    line1,
    line2,
    city,
    region,
    postalCode,
  ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

  factory RecipientAddress.fromJson(Map<String, dynamic> json) {
    return RecipientAddress(
      id: json['id'] as String? ?? '',
      countryId: json['country_id'] as String? ?? '',
      line1: json['line1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      line2: json['line2'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
    );
  }
}

/// Someone the customer sends gifts to. [addresses] is only filled in by the
/// single-recipient endpoint; the list endpoint returns names alone.
class Recipient {
  const Recipient({
    required this.id,
    required this.name,
    this.relationship,
    this.phone,
    this.defaultAddressId,
    this.addresses = const [],
  });

  final String id;
  final String name;
  final String? relationship;
  final String? phone;
  final String? defaultAddressId;
  final List<RecipientAddress> addresses;

  String get label =>
      relationship == null || relationship!.trim().isEmpty
      ? name
      : '$name · $relationship';

  /// Where this recipient would actually be shipped to: their default, or
  /// their only one.
  RecipientAddress? get deliveryAddress {
    for (final address in addresses) {
      if (address.id == defaultAddressId) return address;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  factory Recipient.fromJson(Map<String, dynamic> json) {
    final raw = json['addresses'];
    return Recipient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String?,
      phone: json['phone'] as String?,
      defaultAddressId: json['default_address_id'] as String?,
      addresses: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(RecipientAddress.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// The delivery service chosen for one shop's parcel.
class QuotedShipment {
  const QuotedShipment({
    required this.shopName,
    required this.provider,
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.estimatedDays,
    required this.missesDeliveryDate,
  });

  final String shopName;
  final String provider;
  final String serviceName;

  /// Minor units, in [currency].
  final int amount;
  final String currency;
  final int estimatedDays;

  /// Nothing quoted could make the requested date; the fastest was taken.
  final bool missesDeliveryDate;

  String get summary {
    final days = estimatedDays > 0
        ? ' · $estimatedDays day${estimatedDays == 1 ? '' : 's'}'
        : '';
    return '$shopName · $provider $serviceName$days';
  }

  factory QuotedShipment.fromJson(Map<String, dynamic> json) {
    return QuotedShipment(
      shopName: json['shop_name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      estimatedDays: (json['estimated_days'] as num?)?.toInt() ?? 0,
      missesDeliveryDate: json['misses_delivery_date'] as bool? ?? false,
    );
  }
}

/// What delivery costs for the whole cart.
class DeliveryQuote {
  const DeliveryQuote({
    required this.shipments,
    required this.amount,
    required this.currency,
    required this.complete,
    this.unquoted = const [],
  });

  final List<QuotedShipment> shipments;
  final int amount;
  final String currency;

  /// False when at least one shop could not be priced — no carrier for the
  /// lane, no dispatch address, or shipping switched off. Delivery for those
  /// is arranged after the order.
  final bool complete;
  final List<String> unquoted;

  bool get missesDeliveryDate =>
      shipments.any((shipment) => shipment.missesDeliveryDate);

  /// Delivery is quoted in the carrier's currency, which is not always the
  /// cart's. Adding the two would be nonsense, so a combined total is only
  /// offered when they agree.
  bool matchesCurrency(String cartCurrency) =>
      currency.toUpperCase() == cartCurrency.toUpperCase();

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final raw = json['shipments'];
    final unquoted = json['unquoted'];
    return DeliveryQuote(
      shipments: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(QuotedShipment.fromJson)
                .toList(growable: false)
          : const [],
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      complete: json['complete'] as bool? ?? false,
      unquoted: unquoted is List
          ? unquoted.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}
