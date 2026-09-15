import 'game_2048.dart';

/// One playable game in the collection.
class Game {
  const Game({
    required this.slug,
    required this.name,
    required this.gameType,
    required this.version,
    required this.config,
    this.description,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['config'];
    return Game(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      gameType: json['game_type'] as String? ?? '',
      version: json['version'] as String? ?? '',
      config: GameConfig2048.fromJson(
        rawConfig is Map<String, dynamic> ? rawConfig : const {},
      ),
    );
  }

  static List<Game> listFromJson(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Game.fromJson)
        .toList(growable: false);
  }

  final String slug;
  final String name;
  final String? description;
  final String gameType;
  final String version;
  final GameConfig2048 config;
}

/// A play the server has opened. [seed] is what makes the tiles reproducible:
/// the app generates its board from it, and the backend replays the same one.
class GameSession {
  const GameSession({
    required this.sessionId,
    required this.gameSlug,
    required this.version,
    required this.mode,
    required this.seed,
    required this.config,
    required this.expiresAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['config'];
    return GameSession(
      sessionId: json['session_id'] as String? ?? '',
      gameSlug: json['game_slug'] as String? ?? '',
      version: json['version'] as String? ?? '',
      mode: json['mode'] as String? ?? 'practice',
      seed: json['seed'] as String? ?? '0',
      config: GameConfig2048.fromJson(
        rawConfig is Map<String, dynamic> ? rawConfig : const {},
      ),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
    );
  }

  final String sessionId;
  final String gameSlug;
  final String version;
  final String mode;
  final String seed;
  final GameConfig2048 config;
  final DateTime expiresAt;
}

/// The outcome of a submitted game.
///
/// [score] is the server's own number, recomputed from the submitted moves —
/// not whatever the app had on screen. They match when everything is healthy.
class GameScoreResult {
  const GameScoreResult({
    required this.score,
    required this.highestTile,
    required this.movesCount,
    required this.won,
    required this.gameOver,
    required this.personalBest,
    required this.isPersonalBest,
    required this.accepted,
  });

  factory GameScoreResult.fromJson(Map<String, dynamic> json) {
    return GameScoreResult(
      score: (json['score'] as num?)?.toInt() ?? 0,
      highestTile: (json['highest_tile'] as num?)?.toInt() ?? 0,
      movesCount: (json['moves_count'] as num?)?.toInt() ?? 0,
      won: json['won'] as bool? ?? false,
      gameOver: json['game_over'] as bool? ?? false,
      personalBest: (json['personal_best'] as num?)?.toInt() ?? 0,
      isPersonalBest: json['is_personal_best'] as bool? ?? false,
      accepted: json['accepted'] as bool? ?? false,
    );
  }

  final int score;
  final int highestTile;
  final int movesCount;
  final bool won;
  final bool gameOver;
  final int personalBest;
  final bool isPersonalBest;

  /// False when the server held the score for review, which happens when the
  /// submission looks tampered with or the app is out of date.
  final bool accepted;
}

/// One row of the public board.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.highestTile,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? 'Player',
      score: (json['score'] as num?)?.toInt() ?? 0,
      highestTile: (json['highest_tile'] as num?)?.toInt() ?? 0,
    );
  }

  final int rank;
  final String displayName;
  final int score;
  final int highestTile;
}

/// The board plus this customer's best, when they are signed in.
class Leaderboard {
  const Leaderboard({required this.entries, this.myBest});

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    return Leaderboard(
      entries: rawEntries is List
          ? rawEntries
                .whereType<Map<String, dynamic>>()
                .map(LeaderboardEntry.fromJson)
                .toList(growable: false)
          : const [],
      myBest: (json['my_best'] as num?)?.toInt(),
    );
  }

  final List<LeaderboardEntry> entries;
  final int? myBest;
}
