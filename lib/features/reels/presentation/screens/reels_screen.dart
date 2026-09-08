import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/reels_providers.dart';
import '../widgets/reel_card.dart';

/// Reels: the catalog as a full-screen vertical feed. Swipe up for the next
/// gift, tap to hold the current one, and every clip has a way through to the
/// gift it is showing.
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _advance(int reelCount) {
    // The last reel loops back to the top rather than dead-ending the feed.
    final next = _index + 1 >= reelCount ? 0 : _index + 1;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reels.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, _) => const _ReelsMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Reels are offline',
          description:
              'We could not reach the marketplace just now. Pull up again in '
              'a moment.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _ReelsMessage(
              icon: Icons.play_circle_outline_rounded,
              title: 'No reels yet',
              description:
                  'Sellers have not published anything to watch yet. Browse '
                  'the shelves in the meantime.',
              showExploreAction: true,
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: items.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => ReelCard(
                  reel: items[index],
                  isActive: index == _index,
                  onCompleted: () => _advance(items.length),
                ),
              ),
              const _ReelsHeader(),
            ],
          );
        },
      ),
    );
  }
}

/// Screen title, sitting over the clip rather than in an app bar so the feed
/// keeps the full height.
class _ReelsHeader extends StatelessWidget {
  const _ReelsHeader();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 24,
      left: 20,
      child: Text('Reels', style: AppTypography.display(24, color: Colors.white)),
    );
  }
}

/// Empty and error states share the dark ground, so the feed never flashes a
/// white page between states.
class _ReelsMessage extends StatelessWidget {
  const _ReelsMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.showExploreAction = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showExploreAction;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // EmptyState reads its colours from the theme; on black it needs the
      // light-on-dark pairing.
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white70,
              displayColor: Colors.white,
            ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      child: EmptyState(
        icon: icon,
        title: title,
        description: description,
        action: showExploreAction
            ? ElevatedButton(
                onPressed: () => context.go(AppRoutes.explore),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Browse gifts'),
              )
            : null,
      ),
    );
  }
}
