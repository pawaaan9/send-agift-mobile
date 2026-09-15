import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/game.dart';
import 'guest_player_id.dart';

/// The skill-game collection.
///
/// Reading the catalog is public. Playing needs a player identity, which is
/// either the signed-in customer's bearer token — [ApiClient] attaches that on
/// its own — or this device's guest id. Both are sent; the API prefers the
/// token, so signing in later does not cost anyone their identity mid-session.
class GamesRepository {
  GamesRepository(this._client);

  final ApiClient _client;

  /// Options carrying the device's guest id, so people can play signed out.
  Future<Options> _playerOptions() async {
    return Options(headers: {'X-Guest-Token': await GuestPlayerId.read()});
  }

  /// Every game the platform currently offers.
  Future<List<Game>> listGames() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/games');
    return Game.listFromJson(_map(response.data)['items']);
  });

  /// One game and the rules its current version runs.
  Future<Game> getGame(String slug) => _guard(() async {
    final response = await _client.dio.get<dynamic>('/games/$slug');
    return Game.fromJson(_map(response.data));
  });

  /// Opens a play and returns the server-issued seed.
  ///
  /// The seed comes from the backend so a player cannot restart until they are
  /// dealt an easy board, and so the same game can be replayed at scoring time.
  Future<GameSession> startSession(String slug) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/games/$slug/sessions',
      options: await _playerOptions(),
    );
    return GameSession.fromJson(_map(response.data));
  });

  /// Submits the moves that were played and returns the server's score.
  ///
  /// [clientScore] is what the app had on screen. It is sent only so the
  /// backend can spot a disagreement — the score that counts is the one the
  /// server computes by replaying [moves] itself.
  Future<GameScoreResult> submitScore(
    String sessionId, {
    required List<String> moves,
    required int clientScore,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/games/sessions/$sessionId/submit',
      data: {'moves': moves, 'client_score': clientScore},
      options: await _playerOptions(),
    );
    return GameScoreResult.fromJson(_map(response.data));
  });

  /// The public board, plus this customer's best when they are signed in.
  Future<Leaderboard> leaderboard(String slug, {int limit = 20}) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/games/$slug/leaderboard',
          queryParameters: {'limit': limit},
          // Identity is optional here; it only adds this player's own best.
          options: await _playerOptions(),
        );
        return Leaderboard.fromJson(_map(response.data));
      });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _client.mapError(error);
    }
  }

  static Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const AppException('Unexpected response from the server.');
  }
}
