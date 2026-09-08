import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../saved/data/saved_controller.dart';
import '../../data/reels_providers.dart';
import '../../domain/reel.dart';
import 'reel_video.dart';

/// A single full-bleed reel: the seller's clip, who posted it, and the way
/// through to the gift it is showing.
class ReelCard extends ConsumerStatefulWidget {
  const ReelCard({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onCompleted,
  });

  final Reel reel;

  /// True only for the reel filling the screen — everything else is paused so
  /// off-screen pages are neither playing nor decoding.
  final bool isActive;

  /// Fired when the clip runs out, so the feed can advance.
  final VoidCallback onCompleted;

  @override
  ConsumerState<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends ConsumerState<ReelCard>
    with SingleTickerProviderStateMixin {
  /// How long a photo reel holds before the feed moves on. Video reels run for
  /// their own length instead.
  static const Duration _photoDuration = Duration(seconds: 7);

  late final AnimationController _photoTimer;
  double _videoProgress = 0;
  bool _paused = false;

  bool get _isVideo => widget.reel.hasVideo;
  bool get _playing => widget.isActive && !_paused;

  @override
  void initState() {
    super.initState();
    _photoTimer = AnimationController(vsync: this, duration: _photoDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted();
      });
    if (widget.isActive && !_isVideo) _photoTimer.forward();
  }

  @override
  void didUpdateWidget(covariant ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      // Coming back to a reel restarts it rather than resuming a clip the
      // viewer already half-watched.
      _paused = false;
      _videoProgress = 0;
      if (!_isVideo) _photoTimer.forward(from: 0);
    } else {
      _photoTimer.stop();
      _photoTimer.value = 0;
    }
  }

  @override
  void dispose() {
    _photoTimer.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _paused = !_paused);
    if (_isVideo) return;
    if (_paused) {
      _photoTimer.stop();
    } else {
      _photoTimer.forward();
    }
  }

  void _openGift(ReelProduct product) {
    context.push(AppRoutes.giftDetailPath(product.id));
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final liked = ref.watch(reelLikesProvider).contains(reel.id);
    final product = reel.product;
    final saved = product != null &&
        ref.watch(savedGiftsProvider).contains(product.id);

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideo)
            ReelVideo(
              url: reel.videoUrl!,
              posterUrl: reel.imageUrl,
              playing: _playing,
              onProgress: (value) {
                if (mounted) setState(() => _videoProgress = value);
              },
              onCompleted: widget.onCompleted,
            )
          else if (reel.imageUrl != null)
            _PhotoReel(url: reel.imageUrl!, progress: _photoTimer)
          else
            const ColoredBox(color: Colors.black),
          // Scrims top and bottom: the clip keeps its colour in the middle,
          // and the text on either end stays readable whatever it sits on.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.28, 0.55, 1],
                colors: [
                  Color(0x8C000000),
                  Color(0x1A000000),
                  Color(0x59000000),
                  Color(0xD9000000),
                ],
              ),
            ),
          ),
          _ProgressBar(
            value: _isVideo ? _videoProgress : null,
            photoTimer: _photoTimer,
          ),
          if (_paused) const _PausedGlyph(),
          Positioned(
            right: 12,
            bottom: 40,
            child: _ActionRail(
              liked: liked,
              saved: saved,
              canSave: product != null,
              viewCount: reel.viewCount,
              onLike: () {
                HapticFeedback.lightImpact();
                ref.read(reelLikesProvider.notifier).toggle(reel.id);
              },
              onSave: product == null
                  ? null
                  : () {
                      final nowSaved = ref
                          .read(savedGiftsProvider.notifier)
                          .toggle(product.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              nowSaved
                                  ? 'Saved to your list'
                                  : 'Removed from saved',
                            ),
                            duration: const Duration(milliseconds: 1400),
                          ),
                        );
                    },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReelDetails(reel: reel, onSendGift: _openGift),
          ),
        ],
      ),
    );
  }
}

/// A photo reel: the still, drifting slowly so it reads as footage rather than
/// a picture someone forgot to animate.
class _PhotoReel extends StatelessWidget {
  const _PhotoReel({required this.url, required this.progress});

  final String url;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => Transform.scale(
        scale: 1.06 + (0.08 * progress.value),
        child: child,
      ),
      child: AppNetworkImage(url: url),
    );
  }
}

/// Thin clip timeline under the status bar. A video drives it by position; a
/// photo reel drives it by its hold timer.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.photoTimer});

  final double? value;
  final Animation<double> photoTimer;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: photoTimer,
          builder: (context, _) => LinearProgressIndicator(
            value: value ?? photoTimer.value,
            minHeight: 2.5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Play glyph shown while a reel is held, so tap-to-pause is unmistakable.
class _PausedGlyph extends StatelessWidget {
  const _PausedGlyph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.34),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

/// Right-hand action column: like the clip, save the gift, see the view count.
class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.liked,
    required this.saved,
    required this.canSave,
    required this.viewCount,
    required this.onLike,
    required this.onSave,
  });

  final bool liked;
  final bool saved;
  final bool canSave;
  final int viewCount;
  final VoidCallback onLike;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RailButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? AppColors.destructive : Colors.white,
          label: liked ? 'Liked' : 'Like',
          onTap: onLike,
        ),
        if (canSave && onSave != null) ...[
          const SizedBox(height: 18),
          _RailButton(
            icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? AppColors.teal : Colors.white,
            label: saved ? 'Saved' : 'Save',
            onTap: onSave!,
          ),
        ],
        if (viewCount > 0) ...[
          const SizedBox(height: 18),
          Column(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                _compactCount(viewCount),
                style: const TextStyle(
                  fontFamily: AppTypography.sansFamily,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 1200 → "1.2K". The rail has room for a glance, not a full number.
  static String _compactCount(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}K';
    }
    final millions = count / 1000000;
    return '${millions.toStringAsFixed(millions < 10 ? 1 : 0)}M';
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(icon, key: ValueKey(icon), color: color, size: 30),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.sansFamily,
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the viewer needs to act on the clip: who posted it, what it
/// says, and — when a product is tagged — the price and the way to send it.
class _ReelDetails extends StatelessWidget {
  const _ReelDetails({required this.reel, required this.onSendGift});

  final Reel reel;
  final ValueChanged<ReelProduct> onSendGift;

  @override
  Widget build(BuildContext context) {
    final product = reel.product;
    final caption = reel.caption;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 84, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: reel.shopImageUrl != null
                    ? AppNetworkImage(url: reel.shopImageUrl!)
                    : const Icon(
                        Icons.storefront_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  reel.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.sansFamily,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (product != null) ...[
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(24, color: Colors.white),
            ),
          ],
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.sansFamily,
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
          if (reel.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reel.hashtagLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.sansFamily,
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (product != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    fontFamily: AppTypography.sansFamily,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onSendGift(product),
                    icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Send as a gift'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
