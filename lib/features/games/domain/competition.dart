import 'game.dart';

DateTime? _date(dynamic raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

int? _int(dynamic raw) => raw is num ? raw.toInt() : null;

/// A skill competition: one game, one country, fixed rules and a pre-funded
/// prize. Every entrant plays the identical board, and the highest verified
/// score wins — ties go to the fastest verified time.
class Competition {
  const Competition({
    required this.id,
    required this.title,
    required this.status,
    required this.gameSlug,
    required this.gameName,
    required this.countryName,
    required this.startsAt,
    required this.endsAt,
    required this.pointsPerAttempt,
    required this.pointsDeductionEnabled,
    required this.maxAttempts,
    required this.minAge,
    required this.requiresIdentityVerification,
    required this.numberOfWinners,
    required this.prizeDescription,
    this.prizeValueAmount,
    this.prizeCurrency,
    this.officialRules,
    this.cancelReason,
    this.cancelNote,
    this.me,
    this.winners = const [],
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    final rawMe = json['me'];
    final rawWinners = json['winners'];
    return Competition(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      gameSlug: json['game_slug'] as String? ?? '',
      gameName: json['game_name'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      startsAt: _date(json['starts_at']) ?? DateTime.now(),
      endsAt: _date(json['ends_at']) ?? DateTime.now(),
      pointsPerAttempt: _int(json['points_per_attempt']) ?? 0,
      pointsDeductionEnabled:
          json['points_deduction_enabled'] as bool? ?? false,
      maxAttempts: _int(json['max_attempts_per_customer']) ?? 1,
      minAge: _int(json['min_age']) ?? 18,
      requiresIdentityVerification:
          json['requires_identity_verification'] as bool? ?? true,
      numberOfWinners: _int(json['number_of_winners']) ?? 1,
      prizeDescription: json['prize_description'] as String? ?? '',
      prizeValueAmount: _int(json['prize_value_amount']),
      prizeCurrency: json['prize_currency'] as String?,
      officialRules: json['official_rules'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      cancelNote: json['cancel_note'] as String?,
      me: rawMe is Map<String, dynamic> ? CompetitionMe.fromJson(rawMe) : null,
      winners: rawWinners is List
          ? rawWinners
                .whereType<Map<String, dynamic>>()
                .map(PublicWinner.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  static List<Competition> listFromJson(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Competition.fromJson)
        .toList(growable: false);
  }

  final String id;
  final String title;

  /// scheduled, live, closed, frozen, finalised or cancelled — as decided by
  /// the server clock.
  final String status;
  final String gameSlug;
  final String gameName;
  final String countryName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int pointsPerAttempt;

  /// False until SendAgift Points go live; attempts are free until then.
  final bool pointsDeductionEnabled;
  final int maxAttempts;
  final int minAge;
  final bool requiresIdentityVerification;
  final int numberOfWinners;
  final String prizeDescription;

  /// In minor units (cents).
  final int? prizeValueAmount;
  final String? prizeCurrency;
  final String? officialRules;
  final String? cancelReason;
  final String? cancelNote;

  /// This customer's attempts, eligibility and rank; null for guests.
  final CompetitionMe? me;

  /// Validated winners, published once the result is final.
  final List<PublicWinner> winners;

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'scheduled';
  bool get isCancelled => status == 'cancelled';
  bool get isFinal => status == 'finalised';

  /// Closed for play but the result is still being checked.
  bool get isVerifying => status == 'closed' || status == 'frozen';

  String? get prizeValueLabel {
    final amount = prizeValueAmount;
    final currency = prizeCurrency;
    if (amount == null || currency == null) return null;
    final whole = amount % 100 == 0
        ? '${amount ~/ 100}'
        : (amount / 100).toStringAsFixed(2);
    return '$currency $whole';
  }
}

/// The signed-in customer's position in one competition.
class CompetitionMe {
  const CompetitionMe({
    required this.attemptsUsed,
    required this.attemptsRemaining,
    required this.eligible,
    this.bestScore,
    this.rank,
    this.ineligibleReason,
    this.win,
  });

  factory CompetitionMe.fromJson(Map<String, dynamic> json) {
    final rawWin = json['win'];
    return CompetitionMe(
      attemptsUsed: _int(json['attempts_used']) ?? 0,
      attemptsRemaining: _int(json['attempts_remaining']) ?? 0,
      eligible: json['eligible'] as bool? ?? false,
      bestScore: _int(json['best_score']),
      rank: _int(json['rank']),
      ineligibleReason: json['ineligible_reason'] as String?,
      win: rawWin is Map<String, dynamic> ? MyWin.fromJson(rawWin) : null,
    );
  }

  final int attemptsUsed;
  final int attemptsRemaining;
  final bool eligible;
  final int? bestScore;
  final int? rank;

  /// Why this customer cannot enter, written for them.
  final String? ineligibleReason;
  final MyWin? win;
}

/// Shown only to a winner: their prize and claim.
class MyWin {
  const MyWin({
    required this.winnerId,
    required this.prizePosition,
    required this.status,
    this.claimId,
    this.claimStatus,
    this.claimDeadlineAt,
  });

  factory MyWin.fromJson(Map<String, dynamic> json) {
    return MyWin(
      winnerId: json['winner_id'] as String? ?? '',
      prizePosition: _int(json['prize_position']) ?? 1,
      status: json['status'] as String? ?? '',
      claimId: json['claim_id'] as String?,
      claimStatus: json['claim_status'] as String?,
      claimDeadlineAt: _date(json['claim_deadline_at']),
    );
  }

  final String winnerId;
  final int prizePosition;

  /// pending_validation, validated, disqualified, unclaimed or replaced.
  final String status;
  final String? claimId;

  /// pending, claimed, verified, fulfilled, expired or rejected.
  final String? claimStatus;
  final DateTime? claimDeadlineAt;

  bool get canClaim =>
      status == 'validated' &&
      claimStatus == 'pending' &&
      (claimDeadlineAt?.isAfter(DateTime.now()) ?? false);
}

/// What may be published about a winner: first name, surname initial,
/// country and score.
class PublicWinner {
  const PublicWinner({
    required this.prizePosition,
    required this.displayName,
    required this.countryName,
    required this.score,
  });

  factory PublicWinner.fromJson(Map<String, dynamic> json) {
    return PublicWinner(
      prizePosition: _int(json['prize_position']) ?? 1,
      displayName: json['display_name'] as String? ?? 'Player',
      countryName: json['country_name'] as String? ?? '',
      score: _int(json['score']) ?? 0,
    );
  }

  final int prizePosition;
  final String displayName;
  final String countryName;
  final int score;
}

/// One competition's live board, plus this player's own row.
class CompetitionLeaderboard {
  const CompetitionLeaderboard({
    required this.status,
    required this.isFinal,
    required this.entries,
    required this.totalPlayers,
    this.me,
  });

  factory CompetitionLeaderboard.fromJson(Map<String, dynamic> json) {
    final rawMe = json['me'];
    return CompetitionLeaderboard(
      status: json['status'] as String? ?? '',
      isFinal: json['final'] as bool? ?? false,
      entries: LeaderboardEntry.listFromJson(json['entries']),
      totalPlayers: _int(json['total_players']) ?? 0,
      me: rawMe is Map<String, dynamic>
          ? LeaderboardEntry.fromJson(rawMe)
          : null,
    );
  }

  final String status;
  final bool isFinal;
  final List<LeaderboardEntry> entries;
  final int totalPlayers;
  final LeaderboardEntry? me;
}

/// One of the customer's saved addresses, offered as a prize delivery address.
class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.line1,
    required this.city,
    this.label,
    this.line2,
    this.region,
    this.postalCode,
    this.isDefault = false,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String? ?? '',
      line1: json['line1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      label: json['label'] as String?,
      line2: json['line2'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static List<DeliveryAddress> listFromJson(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(DeliveryAddress.fromJson)
        .toList(growable: false);
  }

  final String id;
  final String line1;
  final String city;
  final String? label;
  final String? line2;
  final String? region;
  final String? postalCode;
  final bool isDefault;

  /// Everything after the first line, e.g. "Flat 2, Auckland, 1010".
  String get summary => [
    line2,
    city,
    region,
    postalCode,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
}

/// An official attempt the server has opened. Its session carries the
/// competition's shared seed — the same board every entrant gets.
class AttemptStart {
  const AttemptStart({
    required this.attemptNumber,
    required this.attemptsRemaining,
    required this.session,
  });

  factory AttemptStart.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    return AttemptStart(
      attemptNumber: _int(json['attempt_number']) ?? 1,
      attemptsRemaining: _int(json['attempts_remaining']) ?? 0,
      session: GameSession.fromJson(
        rawSession is Map<String, dynamic> ? rawSession : const {},
      ),
    );
  }

  final int attemptNumber;
  final int attemptsRemaining;
  final GameSession session;
}
