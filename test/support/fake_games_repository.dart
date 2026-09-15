import 'package:send_agift_mobile/features/games/data/games_repository.dart';
import 'package:send_agift_mobile/features/games/domain/competition.dart';
import 'package:send_agift_mobile/features/games/domain/game.dart';

/// Stands in for the API so game screens can be driven without a backend.
class FakeGamesRepository implements GamesRepository {
  FakeGamesRepository({this.seed = 'cafebabe'});

  /// Fixed so every board — and which moves do something — is predictable.
  final String seed;

  int startCount = 0;
  final List<List<String>> submissions = [];

  List<String>? get lastMoves => submissions.isEmpty ? null : submissions.last;

  static const games = [
    Game(slug: '2048', name: '2048', gameType: 'puzzle', version: '1.0.0', config: {}),
    Game(slug: 'snake', name: 'Snake', gameType: 'timing', version: '1.0.0', config: {}),
    Game(
      slug: 'slide-puzzle',
      name: 'Slide Puzzle',
      gameType: 'puzzle',
      version: '1.0.0',
      config: {},
    ),
  ];

  @override
  Future<GameSession> startSession(String slug) async {
    startCount++;
    return GameSession(
      sessionId: 'session-$startCount',
      gameSlug: slug,
      version: '1.0.0',
      mode: 'practice',
      seed: seed,
      config: const {},
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<GameScoreResult> submitScore(
    String sessionId, {
    required List<String> moves,
    required int clientScore,
  }) async {
    submissions.add(moves);
    return GameScoreResult(
      score: clientScore,
      movesCount: moves.length,
      won: false,
      gameOver: true,
      personalBest: clientScore,
      isPersonalBest: clientScore > 0,
      accepted: true,
      stats: {'moves': moves.length},
    );
  }

  @override
  Future<List<Game>> listGames() async => games;

  @override
  Future<Game> getGame(String slug) async =>
      games.firstWhere((g) => g.slug == slug);

  @override
  Future<Leaderboard> leaderboard(String slug, {int limit = 20}) async =>
      const Leaderboard(entries: []);

  /// Competitions the fake serves; tests set these up as they need.
  List<Competition> competitions = const [];
  CompetitionLeaderboard board = const CompetitionLeaderboard(
    status: 'live',
    isFinal: false,
    entries: [],
    totalPlayers: 0,
  );
  int attemptCount = 0;
  final List<String> claims = [];
  List<DeliveryAddress> addresses = const [];

  @override
  Future<List<DeliveryAddress>> deliveryAddresses() async => addresses;

  @override
  Future<List<Competition>> listCompetitions() async => competitions;

  @override
  Future<Competition> getCompetition(String id) async =>
      competitions.firstWhere((c) => c.id == id);

  @override
  Future<CompetitionLeaderboard> competitionLeaderboard(
    String id, {
    int limit = 50,
  }) async => board;

  @override
  Future<AttemptStart> startAttempt(String competitionId) async {
    attemptCount++;
    final competition = competitions.firstWhere((c) => c.id == competitionId);
    return AttemptStart(
      attemptNumber: attemptCount,
      attemptsRemaining: competition.maxAttempts - attemptCount,
      session: GameSession(
        sessionId: 'official-$attemptCount',
        gameSlug: competition.gameSlug,
        version: '1.0.0',
        mode: 'official',
        seed: seed,
        config: const {},
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<void> claimPrize(
    String competitionId, {
    required String addressId,
  }) async {
    claims.add(addressId);
  }
}
