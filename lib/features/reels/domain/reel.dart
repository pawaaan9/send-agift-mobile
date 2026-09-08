import '../../../core/utils/money.dart';

/// One reel from `GET /reels` — a seller's short video (or photo post),
/// optionally tagged to a product.
///
/// A reel with a [product] is the whole point of the feed: it is a gift you
/// can watch and then send. A reel without one is a shop's own promo, which
/// still plays but has nothing to buy.
class Reel {
  const Reel({
    required this.id,
    required this.shopName,
    this.shopId,
    this.shopImageUrl,
    this.caption,
    this.hashtags = const [],
    this.videoUrl,
    this.imageUrl,
    this.product,
    this.viewCount = 0,
  });

  final String id;
  final String shopName;
  final String? shopId;
  final String? shopImageUrl;
  final String? caption;
  final List<String> hashtags;

  /// First playable video on the reel, if it has one.
  final String? videoUrl;

  /// The still shown while a video loads — and the whole reel for a photo
  /// post. Falls back through thumbnail → first image → nothing.
  final String? imageUrl;

  /// The tagged product. Null for a shop's own promo reel.
  final ReelProduct? product;

  final int viewCount;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// True when there is something to send — drives the gift CTA.
  bool get isShoppable => product != null;

  /// Hashtags as one displayable line, each back in `#tag` form (the API
  /// stores them stripped and lowercased).
  String get hashtagLine =>
      hashtags.isEmpty ? '' : hashtags.map((tag) => '#$tag').join(' ');

  factory Reel.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    final shop = json['shop'] as Map<String, dynamic>?;
    final product = json['product'] as Map<String, dynamic>?;

    return Reel(
      id: json['id'] as String? ?? '',
      shopId: shop?['id'] as String?,
      shopName: (shop?['name'] as String?)?.trim().isNotEmpty == true
          ? shop!['name'] as String
          : 'Send A Gift',
      shopImageUrl: _url(shop?['image_url']),
      caption: (json['caption'] as String?)?.trim(),
      hashtags: (json['hashtags'] as List?)
              ?.map((tag) => tag.toString())
              .where((tag) => tag.isNotEmpty)
              .toList(growable: false) ??
          const [],
      videoUrl: _firstUrlOfType(media, 'video'),
      imageUrl: _mediaUrl(json['thumbnail'] as Map<String, dynamic>?) ??
          _firstUrlOfType(media, 'image') ??
          _url(product?['image_url']),
      product: product == null ? null : ReelProduct.fromJson(product),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Media is playable only through `cdn_url`, which the API fills in just for
  /// objects under `public/`. A private object has no URL the app can open, so
  /// it is treated as absent rather than surfaced as a broken player.
  static String? _mediaUrl(Map<String, dynamic>? item) =>
      item == null ? null : _url(item['cdn_url']);

  static String? _firstUrlOfType(
    List<Map<String, dynamic>> media,
    String assetType,
  ) {
    for (final item in media) {
      if (item['asset_type'] == assetType) {
        final url = _mediaUrl(item);
        if (url != null) return url;
      }
    }
    return null;
  }

  static String? _url(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// The product tagged on a reel — enough to show a price and open the gift.
class ReelProduct {
  const ReelProduct({
    required this.id,
    required this.name,
    required this.priceAmount,
    required this.currency,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int priceAmount;
  final String currency;
  final String? imageUrl;

  String get priceLabel => Money.format(priceAmount, currency);

  factory ReelProduct.fromJson(Map<String, dynamic> json) {
    return ReelProduct(
      id: json['id'] as String? ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Gift',
      priceAmount: (json['price_amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: Reel._url(json['image_url']),
    );
  }
}
