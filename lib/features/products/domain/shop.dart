/// A seller storefront, as returned by `GET /shops`.
class Shop {
  const Shop({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    this.location,
    this.imageUrl,
  });

  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final String? location;
  final String? imageUrl;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Shop',
      description: json['description'] as String?,
      location: json['customer_visible_location'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
