import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../checkout/data/checkout_repository.dart';
import '../../../checkout/domain/checkout.dart';
import '../../../checkout/presentation/widgets/delivery_summary.dart';
import '../../../checkout/presentation/widgets/recipient_picker.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/cart_controller.dart';

/// The one place the app asks for an account. Everything up to here — search,
/// product pages, cart, saved gifts — works as a guest.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _recipientId;
  late DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));

  DeliveryQuote? _quote;
  bool _quoting = false;
  bool _placing = false;
  String? _error;

  /// Identifies the inputs a quote was made for, so a stale response from a
  /// slower earlier request never overwrites a newer one.
  String _quoteToken = '';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final summary = ref.watch(cartSummaryProvider);
    final lines = ref.watch(cartLinesProvider).valueOrNull ?? const [];

    // Re-price whenever the recipient, date or cart changes.
    final token = [
      _recipientId ?? '',
      _dateKey(_deliveryDate),
      for (final line in lines) '${line.gift.id}:${line.quantity}',
    ].join('|');
    if (token != _quoteToken) {
      _quoteToken = token;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            8,
            AppTheme.gutter,
            32,
          ),
          children: [
            FadeSlideIn(
              child: auth.isSignedIn
                  ? _SignedInAs(name: auth.displayName)
                  : const _SignInGate(),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 70),
              child: Text('Order summary', style: AppTypography.display(20)),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: AppPanel(
                child: Column(
                  children: [
                    for (final line in lines) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.quantity} × ${line.gift.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.foreground),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            Money.format(
                              line.lineTotalAmount,
                              line.gift.currency,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Divider(),
                    const SizedBox(height: 10),
                    DeliverySummary(
                      subtotal: summary.subtotal,
                      currency: summary.currency,
                      quote: _quote,
                      loading: _quoting,
                      hasRecipient: _recipientId != null,
                    ),
                  ],
                ),
              ),
            ),
            if (auth.isSignedIn) ...[
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            size: 19,
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Who is it for?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RecipientPicker(
                        selectedId: _recipientId,
                        onChanged: (value) =>
                            setState(() => _recipientId = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 190),
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 19,
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'When should it arrive?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delivery is priced for the date you choose.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(_dateLabel(_deliveryDate)),
                      ),
                      const SizedBox(height: 10),
                      // Shortcuts, because the price moves with the date.
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final preset in const [
                            ('Tomorrow', 1),
                            ('In 3 days', 3),
                            ('Next week', 7),
                          ])
                            ChoiceChip(
                              label: Text(preset.$1),
                              selected: _isSameDay(
                                _deliveryDate,
                                DateTime.now().add(Duration(days: preset.$2)),
                              ),
                              onSelected: (_) => setState(
                                () => _deliveryDate = DateTime.now().add(
                                  Duration(days: preset.$2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppTheme.gutter,
          14,
          AppTheme.gutter,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _placing
                ? null
                : auth.isSignedIn
                ? _placeOrder
                : () => context.push(AppRoutes.login),
            child: _placing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(auth.isSignedIn ? 'Place order' : 'Sign in to continue'),
          ),
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} '
      '${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][date.month - 1]} ${date.year}';

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  /// Prices delivery for the current recipient, date and cart. A failure only
  /// clears the quote: delivery then falls back to being arranged after the
  /// order, which is how checkout worked before pricing existed.
  Future<void> _refreshQuote() async {
    final lines = ref.read(cartLinesProvider).valueOrNull ?? const [];
    final recipientId = _recipientId;
    if (recipientId == null || lines.isEmpty) {
      if (mounted) setState(() => _quote = null);
      return;
    }
    final token = _quoteToken;
    setState(() => _quoting = true);
    try {
      final quote = await ref
          .read(checkoutRepositoryProvider)
          .quoteDelivery(
            recipientId: recipientId,
            deliveryDate: _deliveryDate,
            lines: lines,
          );
      // Another change landed while this was in flight.
      if (!mounted || token != _quoteToken) return;
      setState(() => _quote = quote);
    } on AppException {
      if (mounted && token == _quoteToken) setState(() => _quote = null);
    } finally {
      if (mounted && token == _quoteToken) setState(() => _quoting = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _deliveryDate = picked);
  }

  Future<void> _placeOrder() async {
    final lines = ref.read(cartLinesProvider).valueOrNull ?? const [];
    if (lines.isEmpty) return;
    setState(() {
      _placing = true;
      _error = null;
    });

    final repository = ref.read(checkoutRepositoryProvider);
    final summary = ref.read(cartSummaryProvider);
    try {
      var countryId = '';
      // Deliver to the recipient's own country when we know it, so the order
      // is not filed under the buyer's country by default.
      final recipientId = _recipientId;
      if (recipientId != null) {
        final recipient = await repository.getRecipient(recipientId);
        countryId = recipient.deliveryAddress?.countryId ?? '';
      }
      if (countryId.isEmpty) countryId = await repository.myCountryId();

      final quote = _quote;
      final orderId = await repository.placeOrder(
        countryId: countryId,
        deliveryDate: _deliveryDate,
        lines: lines,
        recipientId: recipientId,
        // Only a quote in the cart's own currency can be stored against the
        // order, which holds a bare integer.
        deliveryAmount: quote != null &&
                quote.complete &&
                quote.matchesCurrency(summary.currency)
            ? quote.amount
            : null,
      );

      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('${AppRoutes.orders}/$orderId');
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

class _SignInGate extends StatelessWidget {
  const _SignInGate();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in to finish',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your cart is saved on this device. Sign in — or create an account '
            'in a minute — to place the order and track delivery.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
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

class _SignedInAs extends StatelessWidget {
  const _SignedInAs({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Signed in as $name',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
