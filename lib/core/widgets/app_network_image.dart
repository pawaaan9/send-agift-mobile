import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Remote image with a shimmer placeholder and a graceful fallback, so a slow
/// or broken photo never leaves a hard grey box in the layout.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: AppColors.muted,
        highlightColor: AppColors.surface,
        child: Container(color: AppColors.muted),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.mist,
        alignment: Alignment.center,
        child: const Icon(
          Icons.card_giftcard_rounded,
          color: AppColors.mutedForeground,
          size: 28,
        ),
      ),
    );
  }
}
