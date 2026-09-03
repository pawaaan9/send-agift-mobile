import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Editorial hero. Leads with the browse-first promise: no account needed
/// until there is something to check out or track.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        4,
        AppTheme.gutter,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FROM MOMENTS TO MEMORIES', style: AppTypography.eyebrow),
          const SizedBox(height: 12),
          Text(
            'Discover the best gifts for every moment.',
            style: AppTypography.display(33),
          ),
          const SizedBox(height: 12),
          Text(
            'Browse gifts right away — no account needed. Sign in when you '
            'want to save favourites, check out, and track deliveries.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedForeground,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.explore),
                  icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                  label: const Text('Browse gifts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _HeroCollage(),
          const SizedBox(height: 22),
          const _HeroStats(),
        ],
      ),
    );
  }
}

/// Three-photo collage standing in for the web hero's photographic backdrop.
class _HeroCollage extends StatelessWidget {
  const _HeroCollage();

  static const _tall =
      'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?auto=format&fit=crop&w=800&q=80';
  static const _topRight =
      'https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=600&q=80';
  static const _bottomRight =
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=600&q=80';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Row(
        // Stretch, so the tall photo fills the column instead of shrinking to
        // its intrinsic aspect ratio.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius2xl),
              child: const AppNetworkImage(url: _tall),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: const AppNetworkImage(url: _topRight),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: const AppNetworkImage(url: _bottomRight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: const [
          _Stat(value: '10K+', label: 'Happy gifters'),
          SizedBox(width: 36),
          _Stat(value: '2.4K+', label: 'Curated gifts'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.display(26)),
        const SizedBox(height: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
