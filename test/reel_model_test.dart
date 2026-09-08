import 'package:flutter_test/flutter_test.dart';
import 'package:send_agift_mobile/features/reels/domain/reel.dart';

/// A ReelDetails payload shaped exactly like the one in API_REFERENCE 5.14.
Map<String, dynamic> _payload({
  Map<String, dynamic>? product,
  List<Map<String, dynamic>>? media,
  Map<String, dynamic>? thumbnail,
}) {
  return {
    'id': 'e51a',
    'seller_id': '77aa',
    'shop_id': 'd40b',
    'product_id': product?['id'],
    'reel_type': 'video',
    'caption': 'Check out our Gift Box USA',
    'hashtags': ['giftbox', 'birthday'],
    'visibility': 'public',
    'status': 'published',
    'duration_ms': 15000,
    'view_count': 1200,
    'media': media ??
        [
          {
            'media_asset_id': 'a91c',
            'position': 0,
            'asset_type': 'video',
            'bucket': 'sendagift-media',
            'object_path': 'public/reels/videos/unboxing.mp4',
            'cdn_url': 'https://cdn.test/public/reels/videos/unboxing.mp4',
            'mime_type': 'video/mp4',
            'size_bytes': 2481920,
          },
        ],
    'thumbnail': thumbnail,
    'shop': {
      'id': 'd40b',
      'name': 'Bay Area Gifts',
      'slug': 'bay-area-gifts',
      'image_url': null,
    },
    'product': product,
  };
}

void main() {
  test('maps a product reel from the feed payload', () {
    final reel = Reel.fromJson(_payload(
      product: {
        'id': 'p-1',
        'name': 'Gift Box USA',
        'slug': 'gift-box-usa',
        'price_amount': 4200,
        'currency': 'USD',
        'status': 'published',
        'image_url': 'https://cdn.test/public/products/box.jpg',
      },
      thumbnail: {
        'media_asset_id': 'b220',
        'asset_type': 'image',
        'object_path': 'public/reels/thumbnails/cover.jpg',
        'cdn_url': 'https://cdn.test/public/reels/thumbnails/cover.jpg',
        'mime_type': 'image/jpeg',
      },
    ));

    expect(reel.id, 'e51a');
    expect(reel.shopName, 'Bay Area Gifts');
    expect(reel.hasVideo, isTrue);
    expect(reel.videoUrl, 'https://cdn.test/public/reels/videos/unboxing.mp4');
    expect(reel.imageUrl, 'https://cdn.test/public/reels/thumbnails/cover.jpg');
    expect(reel.viewCount, 1200);
    expect(reel.hashtagLine, '#giftbox #birthday');

    expect(reel.isShoppable, isTrue);
    expect(reel.product!.id, 'p-1');
    expect(reel.product!.priceLabel, 'USD 42.00');
  });

  test('a shop promo reel has no product to send', () {
    final reel = Reel.fromJson(_payload());

    expect(reel.isShoppable, isFalse);
    expect(reel.product, isNull);
  });

  test('media with no cdn_url is treated as absent, not as a broken player',
      () {
    // The API fills cdn_url only for objects under public/; a private object
    // has no URL the app could open.
    final reel = Reel.fromJson(_payload(
      media: [
        {
          'media_asset_id': 'a91c',
          'asset_type': 'video',
          'object_path': 'private/reels/videos/unboxing.mp4',
          'mime_type': 'video/mp4',
        },
      ],
    ));

    expect(reel.hasVideo, isFalse);
    expect(reel.videoUrl, isNull);
  });

  test('keeps every photo in position order for a carousel', () {
    // The API allows up to ten images on one post, ordered by `position`.
    final reel = Reel.fromJson(_payload(
      media: [
        {
          'media_asset_id': 'b',
          'position': 1,
          'asset_type': 'image',
          'object_path': 'public/reels/photos/two.jpg',
          'cdn_url': 'https://cdn.test/two.jpg',
          'mime_type': 'image/jpeg',
        },
        {
          'media_asset_id': 'a',
          'position': 0,
          'asset_type': 'image',
          'object_path': 'public/reels/photos/one.jpg',
          'cdn_url': 'https://cdn.test/one.jpg',
          'mime_type': 'image/jpeg',
        },
      ],
    ));

    expect(reel.photoUrls, [
      'https://cdn.test/one.jpg',
      'https://cdn.test/two.jpg',
    ]);
    expect(reel.isCarousel, isTrue);
  });

  test('falls back to the first image when there is no thumbnail', () {
    final reel = Reel.fromJson(_payload(
      media: [
        {
          'media_asset_id': 'c33d',
          'asset_type': 'image',
          'object_path': 'public/reels/photos/one.jpg',
          'cdn_url': 'https://cdn.test/public/reels/photos/one.jpg',
          'mime_type': 'image/jpeg',
        },
      ],
    ));

    expect(reel.hasVideo, isFalse);
    expect(reel.imageUrl, 'https://cdn.test/public/reels/photos/one.jpg');
  });
}
