import '../../products/domain/gift.dart';

/// One vertical clip in the reels feed.
///
/// A reel is always tied to a gift — the feed is a way to browse the catalog,
/// not a separate content library — so tapping through always has somewhere
/// to land.
///
/// [videoUrl] is null for every reel the catalog produces today: sellers
/// upload stills, and the screen animates them. It is here so real clips can
/// be dropped in per-reel later without reshaping the feed.
class Reel {
  const Reel({
    required this.id,
    required this.gift,
    required this.caption,
    this.videoUrl,
  });

  final String id;
  final Gift gift;
  final String caption;
  final String? videoUrl;

  /// The still shown while a clip loads — and, for now, the clip itself.
  String get posterImage => gift.image;

  String get shopName => gift.shopName ?? 'Send A Gift';

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Builds a reel from a catalog gift. Captions lean on the gift's own copy
  /// so the feed reads in the seller's voice rather than in filler.
  factory Reel.fromGift(Gift gift) {
    final description = gift.description.trim();

    return Reel(
      id: 'reel-${gift.id}',
      gift: gift,
      caption: description.isNotEmpty
          ? description
          : 'A little something worth sending.',
    );
  }
}
