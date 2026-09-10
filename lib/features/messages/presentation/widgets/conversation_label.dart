import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../products/data/catalog_providers.dart';
import '../../domain/chat.dart';

/// How a thread is named on the customer's side.
class ConversationLabel {
  const ConversationLabel({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.isSupport = false,
    this.giftName,
    this.giftImageUrl,
    this.shopImageUrl,
  });

  final String title;
  final String subtitle;

  /// Avatar photo: the shop's, or the gift's when the shop has none.
  final String? imageUrl;
  final bool isSupport;

  /// The gift the thread is about, when the catalog knows it.
  final String? giftName;
  final String? giftImageUrl;
  final String? shopImageUrl;

  /// What the inbox search matches against.
  String get searchText =>
      [title, subtitle, giftName ?? ''].join(' ').toLowerCase();
}

/// Names a thread from the catalog: the API only returns ids, so the shop and
/// gift names come from the same lookup the gift page uses.
ConversationLabel watchConversationLabel(
  WidgetRef ref, {
  required String type,
  String? productId,
  ChatSupportCase? supportCase,
}) {
  if (type == 'support') {
    final subject = supportCase?.subject;
    return ConversationLabel(
      title: 'SendAGift Support',
      subtitle: subject == null || subject.isEmpty
          ? 'Help from our team'
          : subject,
      isSupport: true,
    );
  }

  final gift = productId == null
      ? null
      : ref.watch(giftByIdProvider(productId)).valueOrNull;
  final String subtitle;
  if (type == 'order') {
    subtitle = gift == null ? 'Order question' : 'Order · ${gift.name}';
  } else {
    subtitle = gift?.name ?? 'Question about a gift';
  }

  return ConversationLabel(
    title: gift?.shopName ?? 'Shop',
    subtitle: subtitle,
    imageUrl: gift?.shopImageUrl ?? gift?.image,
    giftName: gift?.name,
    giftImageUrl: gift?.image,
    shopImageUrl: gift?.shopImageUrl,
  );
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.label, this.size = 44});

  final ConversationLabel label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = label.imageUrl;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: label.isSupport ? AppColors.primary : AppColors.accent,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? AppNetworkImage(url: imageUrl)
          : Icon(
              label.isSupport
                  ? Icons.support_agent_rounded
                  : Icons.storefront_rounded,
              size: size * 0.45,
              color: label.isSupport
                  ? AppColors.primaryForeground
                  : AppColors.accentForeground,
            ),
    );
  }
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _daysAgo(DateTime value) {
  final local = value.toLocal();
  return _startOfDay(DateTime.now()).difference(_startOfDay(local)).inDays;
}

/// Inbox timestamp: a time today, a weekday this week, a date otherwise.
String formatInboxTime(DateTime value) {
  final local = value.toLocal();
  final ago = _daysAgo(local);
  if (ago <= 0) return DateFormat.jm().format(local);
  if (ago == 1) return 'Yesterday';
  if (ago < 7) return DateFormat.E().format(local);
  return DateFormat.MMMd().format(local);
}

/// Separator between days inside a thread.
String formatDayLabel(DateTime value) {
  final local = value.toLocal();
  final ago = _daysAgo(local);
  if (ago <= 0) return 'Today';
  if (ago == 1) return 'Yesterday';
  return DateFormat.MMMMEEEEd().format(local);
}

String formatBubbleTime(DateTime value) =>
    DateFormat.jm().format(value.toLocal());

bool isSameDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
}
