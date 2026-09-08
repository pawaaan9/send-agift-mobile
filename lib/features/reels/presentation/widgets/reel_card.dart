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

/// A single full-bleed reel: the gift photo drifting under a scrim, the
/// seller's line, and the actions that matter here — like, save, open.
///
/// Until sellers upload real clips, "playback" is a slow push-in on the still
/// plus a progress bar that hands off to the next reel. Both are driven by one
/// controller, so swapping in a video player later means replacing the visual
/// and letting the player report progress.
class ReelCard extends ConsumerStatefulWidget {
  const ReelCard({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onCompleted,
  });

  final Reel reel;

  /// True only for the reel filling the screen — everything else is paused so
  /// off-screen pages aren't animating.
  final bool isActive;

  /// Fired when the clip runs out, so the feed can advance.
  final VoidCallback onCompleted;

  @override
  ConsumerState<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends ConsumerState<ReelCard>
    with SingleTickerProviderStateMixin {
  static const Duration _clipLength = Duration(seconds: 7);

  late final AnimationController _controller;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _clipLength)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted();
      });
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      // Scrolling back to a reel restarts it rather than resuming a clip the
      // viewer has already half-watched.
      _paused = false;
      _controller.forward(from: 0);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _controller.stop();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final gift = reel.gift;
    final liked = ref.watch(reelLikesProvider).contains(reel.id);
    final saved = ref.watch(savedGiftsProvider).contains(gift.id);

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The clip itself: a slow push-in, so a still frame still reads as
          // footage rather than a photo someone forgot to animate.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: 1.06 + (0.08 * _controller.value),
              child: child,
            ),
            child: AppNetworkImage(url: reel.posterImage),
          ),
          // Scrims top and bottom: the photo keeps its colour in the middle,
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
          _ProgressBar(progress: _controller),
          if (_paused) const _PausedGlyph(),
          Positioned(
            right: 12,
            bottom: 40,
            child: _ActionRail(
              liked: liked,
              saved: saved,
              rating: gift.rating,
              reviewCount: gift.reviewCount,
              onLike: () {
                HapticFeedback.lightImpact();
                ref.read(reelLikesProvider.notifier).toggle(reel.id);
              },
              onSave: () {
                final nowSaved =
                    ref.read(savedGiftsProvider.notifier).toggle(gift.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        nowSaved ? 'Saved to your list' : 'Removed from saved',
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
            child: _ReelDetails(reel: reel),
          ),
        ],
      ),
    );
  }
}

/// Thin clip timeline under the status bar.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => LinearProgressIndicator(
            value: progress.value,
            minHeight: 2.5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Play glyph shown while a reel is held, so a tap-to-pause is unmistakable.
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

/// Right-hand action column: like the clip, save the gift, see the rating.
class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.liked,
    required this.saved,
    required this.rating,
    required this.reviewCount,
    required this.onLike,
    required this.onSave,
  });

  final bool liked;
  final bool saved;
  final double rating;
  final int reviewCount;
  final VoidCallback onLike;
  final VoidCallback onSave;

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
        const SizedBox(height: 18),
        _RailButton(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: saved ? AppColors.teal : Colors.white,
          label: saved ? 'Saved' : 'Save',
          onTap: onSave,
        ),
        if (reviewCount > 0) ...[
          const SizedBox(height: 18),
          Column(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.star, size: 26),
              const SizedBox(height: 4),
              Text(
                rating.toStringAsFixed(1),
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

/// Everything the viewer needs to act on the clip: who made it, what it is,
/// what it costs, and the way through to the gift.
class _ReelDetails extends StatelessWidget {
  const _ReelDetails({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final gift = reel.gift;

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
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: gift.shopImageUrl != null
                    ? AppNetworkImage(url: gift.shopImageUrl!)
                    : const ColoredBox(
                        color: AppColors.primary,
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
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
          const SizedBox(height: 12),
          Text(
            gift.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(24, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            reel.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.sansFamily,
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                gift.priceLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.sansFamily,
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  // No hero tag: the clip fills the screen already, so the
                  // detail page fades in rather than flying an image from
                  // edge to edge.
                  onPressed: () =>
                      context.push(AppRoutes.giftDetailPath(gift.id)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('View gift'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
