import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/checkout_repository.dart';

/// Picks who the gift goes to, and shows the address it would ship to.
///
/// The address matters at checkout, not just the name: delivery is priced
/// against it, and it is the last chance to notice the gift is pointed at the
/// wrong place.
class RecipientPicker extends ConsumerWidget {
  const RecipientPicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recipients = ref.watch(recipientsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        recipients.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => Text(
            'Could not load your recipients.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.destructive,
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'You have no saved recipients yet. The gift will be sent '
                'without one, and delivery is arranged after ordering.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground,
                  height: 1.35,
                ),
              );
            }
            return DropdownButtonFormField<String?>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Send to'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Send without a recipient'),
                ),
                for (final recipient in list)
                  DropdownMenuItem<String?>(
                    value: recipient.id,
                    child: Text(
                      recipient.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            );
          },
        ),
        if (selectedId != null) _Address(recipientId: selectedId!),
      ],
    );
  }
}

class _Address extends ConsumerWidget {
  const _Address({required this.recipientId});

  final String recipientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final details = ref.watch(recipientDetailsProvider(recipientId));

    return details.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (recipient) {
        final address = recipient.deliveryAddress;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream,
                ),
                child: Text(
                  _initials(recipient.name),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipient.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      address?.formatted ??
                          'No saved address — delivery cannot be priced yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForeground,
                        height: 1.35,
                      ),
                    ),
                    if (recipient.phone != null &&
                        recipient.phone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        recipient.phone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
