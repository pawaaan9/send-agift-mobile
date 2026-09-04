import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/fade_slide_in.dart';

/// Editorial hero. Leads with the browse-first promise: no account needed
/// until there is something to check out or track.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  static const _stagger = Duration(milliseconds: 70);

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
          const FadeSlideIn(child: _Eyebrow()),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: _stagger,
            child: Text(
              'Discover the best gifts for every moment.',
              style: AppTypography.display(33),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: _stagger * 2,
            child: Text(
              'Browse gifts right away — no account needed. Sign in when you '
              'want to save favourites, check out, and track deliveries.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: _stagger * 3,
            child: Row(
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
          ),
          const SizedBox(height: 24),
          FadeSlideIn(delay: _stagger * 4, child: const _HeroCollage()),
          const SizedBox(height: 22),
          FadeSlideIn(delay: _stagger * 5, child: const _HeroStats()),
        ],
      ),
    );
  }
}

/// Uppercase eyebrow label above the headline.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
        const SizedBox(width: 6),
        Text('FROM MOMENTS TO MEMORIES', style: AppTypography.eyebrow),
      ],
    );
  }
}

/// Three-photo collage standing in for the web hero's photographic backdrop,
/// with a floating badge calling out same-day delivery.
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 230,
          child: Row(
            // Stretch, so the tall photo fills the column instead of
            // shrinking to its intrinsic aspect ratio.
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
        ),
        Positioned(
          left: 14,
          bottom: -16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 22,
                  width: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Same-day options',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          _Stat(
            icon: Icons.diversity_3_rounded,
            value: '10K+',
            label: 'Happy gifters',
          ),
          SizedBox(width: 30),
          _Stat(
            icon: Icons.card_giftcard_rounded,
            value: '2.4K+',
            label: 'Curated gifts',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, size: 16, color: AppColors.accentForeground),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.display(22)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
