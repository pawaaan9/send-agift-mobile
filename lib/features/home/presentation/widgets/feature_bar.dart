import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The four trust promises the web home page runs under its hero.
class FeatureBar extends StatelessWidget {
  const FeatureBar({super.key});

  static const _features = <({IconData icon, String title, String description})>[
    (
      icon: Icons.local_shipping_outlined,
      title: 'Country delivery',
      description: 'Gifts filtered by active countries.',
    ),
    (
      icon: Icons.shield_outlined,
      title: 'Secure payments',
      description: 'Provider-approved checkout.',
    ),
    (
      icon: Icons.refresh_rounded,
      title: 'Easy returns',
      description: 'Clear refund pathways.',
    ),
    (
      icon: Icons.headset_mic_outlined,
      title: '24/7 support',
      description: 'Help with any order.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        itemCount: _features.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final feature = _features[index];
          return Container(
            width: 158,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(feature.icon, size: 20, color: AppColors.primary),
                const Spacer(),
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  feature.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
