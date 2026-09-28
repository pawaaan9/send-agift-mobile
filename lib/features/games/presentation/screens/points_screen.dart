import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/games_providers.dart';
import '../../domain/competition.dart';
import '../competition_format.dart';

/// The customer's SendAgift Points: the balance plays are paid from, and
/// every change to it. Nothing here is hidden — a play, a refund and a grant
/// each show with the balance after it.
class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(pointsWalletProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My points')),
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Could not load your points',
          description: '$error',
          action: FilledButton(
            onPressed: () => ref.invalidate(pointsWalletProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (w) => RefreshIndicator(
          onRefresh: () => ref.refresh(pointsWalletProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              16,
              AppTheme.gutter,
              32,
            ),
            children: [
              _Balance(wallet: w),
              const SizedBox(height: 12),
              _HowToEarn(
                rule: ref.watch(pointsEarningRuleProvider).valueOrNull,
              ),
              const SizedBox(height: 8),
              Text(
                'Each competition play costs the points shown on its Play '
                'button, and a play that is voided or a round that is '
                'cancelled gives them back.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text('HISTORY', style: AppTypography.eyebrow),
              const SizedBox(height: 8),
              if (w.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No points activity yet.')),
                )
              else
                for (final e in w.entries) _EntryRow(entry: e),
            ],
          ),
        ),
      ),
    );
  }
}

/// How points are earned in the customer's country, from its earning rule.
class _HowToEarn extends StatelessWidget {
  const _HowToEarn({required this.rule});

  final PointsEarningRule? rule;

  @override
  Widget build(BuildContext context) {
    final r = rule;
    final String text;
    if (r == null) {
      text = 'Points are credited to your account by SendAgift.';
    } else if (r.earnsOnOrders) {
      text =
          'Earn ${r.pointsPerUnit} '
          '${r.pointsPerUnit == 1 ? 'point' : 'points'} for every '
          '${r.currency} 1 you spend, once your order is delivered. Points '
          'from an order that is refunded are taken back.';
    } else {
      text =
          'Points are credited to your account by SendAgift, for example '
          'through promotions.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.wallet});

  final PointsWallet wallet;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.white.withValues(alpha: 0.85));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF0EA5A4)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance', style: muted),
          Text(
            '${wallet.balance} points',
            style: AppTypography.display(34, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${wallet.lifetimeEarned} received · ${wallet.lifetimeSpent} spent',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final PointsEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final positive = e.amountDelta > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  (positive
                          ? AppColors.accentForeground
                          : AppColors.destructive)
                      .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.sports_esports_rounded,
              size: 18,
              color: positive
                  ? AppColors.accentForeground
                  : AppColors.destructive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  [
                    formatDateTime(e.createdAt),
                    if (e.reason != null && e.entryType != 'play_debit')
                      e.reason!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : ''}${e.amountDelta}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: positive
                      ? AppColors.accentForeground
                      : AppColors.destructive,
                ),
              ),
              Text(
                '= ${e.balanceAfter}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
