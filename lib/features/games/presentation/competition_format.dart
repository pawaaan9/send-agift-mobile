/// Small text helpers shared by the competition and leaderboard screens.
library;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A countdown such as "2d 04:12:09", "04:12:09" or "12:09".
String formatCountdown(Duration left) {
  final d = left.isNegative ? Duration.zero : left;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = two(d.inHours.remainder(24));
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  if (d.inDays > 0) return '${d.inDays}d $h:$m:$s';
  if (d.inHours > 0) return '$h:$m:$s';
  return '$m:$s';
}

/// Server-measured play time, e.g. "42.6s" or "3:05".
String formatPlayTime(int ms) {
  if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
  final seconds = (ms % 60000) ~/ 1000;
  return '${ms ~/ 60000}:${seconds.toString().padLeft(2, '0')}';
}

/// "1st", "2nd", "3rd", "11th"…
String ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// A local date and time such as "15 Sep, 18:30".
String formatDateTime(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]}, $h:$m';
}

/// Why a competition was cancelled, in words, for "cancelled because of …".
String cancelReasonText(String? reason) => switch (reason) {
  'technical_failure' => 'a technical failure',
  'security_breach' => 'a security issue',
  'legal_direction' => 'a legal direction',
  'provider_or_store_direction' => 'a platform or app store direction',
  'platform_outage' => 'a platform outage',
  'prize_unavailable' => 'the prize becoming unavailable',
  'fairness_failure' => 'a fairness problem',
  _ => 'an operational issue',
};
