import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/data/games_repository.dart';
import 'package:send_agift_mobile/features/games/domain/game.dart';
import 'package:send_agift_mobile/features/games/domain/game_2048.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/game_2048_screen.dart';

/// Stands in for the API so the screen can be driven without a backend.
///
/// The seed is fixed, which makes the board — and therefore which swipes do
/// something — completely predictable.
class _FakeGamesRepository implements GamesRepository {
  /// Opens with both tiles off the left wall, so a left swipe always moves
  /// something — see the engine test's golden board for this seed.
  static const String seed = 'cafebabe';

  int startCount = 0;
  List<String>? submittedMoves;
  int? submittedClientScore;

  @override
  Future<GameSession> startSession(String slug) async {
    startCount++;
    return GameSession(
      sessionId: 'test-session',
      gameSlug: slug,
      version: '1.0.0',
      mode: 'practice',
      seed: seed,
      config: const GameConfig2048(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<GameScoreResult> submitScore(
    String sessionId, {
    required List<String> moves,
    required int clientScore,
  }) async {
    submittedMoves = moves;
    submittedClientScore = clientScore;
    return GameScoreResult(
      score: clientScore,
      highestTile: 4,
      movesCount: moves.length,
      won: false,
      gameOver: false,
      personalBest: clientScore,
      isPersonalBest: true,
      accepted: true,
    );
  }

  @override
  Future<List<Game>> listGames() async => const [];

  @override
  Future<Game> getGame(String slug) async =>
      throw UnimplementedError('not used by this screen');

  @override
  Future<Leaderboard> leaderboard(String slug, {int limit = 20}) async =>
      const Leaderboard(entries: []);
}

Widget _wrap(_FakeGamesRepository repo) {
  return ProviderScope(
    overrides: [gamesRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: Game2048Screen()),
  );
}

/// The default 800x600 test surface is nothing like a phone and pushes the
/// controls below the fold. Every test runs on an iPhone-sized viewport.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Drags across the middle of the board fast enough to register as a swipe.
Future<void> _swipe(WidgetTester tester, Offset delta) async {
  await tester.fling(find.byType(GestureDetector).first, delta, 1200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens a session and shows the seeded board', (tester) async {
    _usePhoneScreen(tester);
    final repo = _FakeGamesRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(repo.startCount, 1);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('MOVES'), findsOneWidget);

    // Nothing has been played, so there is nothing to submit yet.
    final submit = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(submit.onPressed, isNull);
  });

  testWidgets('a swipe moves the board and counts the move', (tester) async {
    _usePhoneScreen(tester);
    final repo = _FakeGamesRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Seed 'cafebabe' opens with both tiles off the left wall, so a left
    // swipe is guaranteed to change the board.
    await _swipe(tester, const Offset(-300, 0));

    // The moves counter sits under the MOVES label.
    expect(find.text('1'), findsWidgets);

    // Having played, the player can now bank the round.
    final submit = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(submit.onPressed, isNotNull);
  });

  testWidgets('submits the move log, not just a score', (tester) async {
    _usePhoneScreen(tester);
    final repo = _FakeGamesRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await _swipe(tester, const Offset(-300, 0));
    await _swipe(tester, const Offset(0, -300));

    await tester.tap(find.text('Finish and submit'));
    await tester.pumpAndSettle();

    // The whole point of the design: the server gets the moves.
    expect(repo.submittedMoves, isNotNull);
    expect(repo.submittedMoves, contains(Move2048.left));
    expect(repo.submittedMoves, contains(Move2048.up));
    expect(repo.submittedClientScore, isNotNull);

    // The result sheet reports back what the server said.
    expect(find.text('New personal best'), findsOneWidget);
  });

  testWidgets('play again starts a fresh session', (tester) async {
    _usePhoneScreen(tester);
    final repo = _FakeGamesRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await _swipe(tester, const Offset(-300, 0));
    await tester.tap(find.text('Finish and submit'));
    await tester.pumpAndSettle();

    // Two "Play again" buttons exist once the sheet is up — the sheet's and
    // the one behind it. hitTestable picks the one a player could actually
    // press, which is the sheet's.
    await tester.tap(find.text('Play again').hitTestable());
    await tester.pumpAndSettle();

    expect(repo.startCount, 2);
  });
}
