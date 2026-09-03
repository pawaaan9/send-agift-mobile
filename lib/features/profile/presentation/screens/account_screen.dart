import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../saved/data/saved_controller.dart';

/// Customer account hub. The mobile app is customer-only — there are no
/// seller or admin surfaces here; those stay on the web app.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final savedCount = ref.watch(savedGiftsProvider).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                10,
                AppTheme.gutter,
                18,
              ),
              child: Text('Account', style: AppTypography.display(28)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              child: auth.isSignedIn
                  ? _SignedInCard(name: auth.displayName, email: auth.email)
                  : const _GuestCard(),
            ),
            const SizedBox(height: 26),
            _MenuSection(
              title: 'Shopping',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'My orders',
                  subtitle: 'Track deliveries and view history',
                  onTap: () => context.push(AppRoutes.orders),
                ),
                _MenuItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'Saved gifts',
                  subtitle: savedCount == 0
                      ? 'Nothing saved yet'
                      : '$savedCount saved',
                  onTap: () => context.go(AppRoutes.saved),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Addresses',
                  subtitle: 'Delivery and return addresses',
                  onTap: () => _requiresAccount(context, auth.isSignedIn),
                ),
                _MenuItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Recipients',
                  subtitle: 'People you send gifts to',
                  onTap: () => _requiresAccount(context, auth.isSignedIn),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _MenuSection(
              title: 'Support',
              items: [
                _MenuItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Help centre',
                  subtitle: 'Orders, points, and competitions',
                  onTap: () => _notYetAvailable(context),
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: 'Terms & privacy',
                  onTap: () => _notYetAvailable(context),
                ),
              ],
            ),
            if (auth.isSignedIn) ...[
              const SizedBox(height: 26),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _requiresAccount(BuildContext context, bool isSignedIn) {
    if (!isSignedIn) {
      context.push(AppRoutes.login);
      return;
    }
    _notYetAvailable(context);
  }

  static void _notYetAvailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Coming soon.')),
      );
  }
}

/// Guest header. Reinforces that an account is optional and says exactly what
/// signing in adds.
class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("You're browsing as a guest",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Search, save gifts, and build a cart without an account. Sign in '
            'to check out, track deliveries, and sync across devices.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.name, this.email});

  final String name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: AppTypography.display(22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            0,
            AppTheme.gutter,
            10,
          ),
          child: Text(title.toUpperCase(), style: AppTypography.eyebrow),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: AppPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i != items.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 56),
                      child: Divider(height: 1),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
