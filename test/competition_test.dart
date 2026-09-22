import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/domain/competition.dart';
import 'package:send_agift_mobile/features/games/domain/game.dart';
import 'package:send_agift_mobile/features/games/presentation/game_definitions.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/competition_screen.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/game_play_screen.dart';

import 'support/fake_games_repository.dart';

/// Countdowns and the live pulse run forever, so frames are pumped for a
/// fixed time instead of pumpAndSettle.
Future<void> _frames(WidgetTester tester, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Competition _competition({
  String status = 'live',
  CompetitionMe? me,
  List<PublicWinner> winners = const [],
}) {
  return Competition(
    id: 'c1',
    title: 'Spring 2048 Cup',
    status: status,
    gameSlug: '2048',
    gameName: '2048',
    countryName: 'New Zealand',
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 5)),
    pointsPerAttempt: 50,
    pointsDeductionEnabled: false,
    maxAttempts: 3,
    minAge: 18,
    requiresIdentityVerification: true,
    numberOfWinners: 1,
    prizeDescription: r'NZ$50 gift card',
    prizeValueAmount: 5000,
    prizeCurrency: 'NZD',
    officialRules: 'Highest verified score wins.',
    me: me,
    winners: winners,
  );
}

const _eligible = CompetitionMe(
  attemptsUsed: 1,
  attemptsRemaining: 2,
  eligible: true,
);

Future<FakeGamesRepository> _openCompetition(
  WidgetTester tester,
  Competition competition, {
  CompetitionLeaderboard? board,
  List<DeliveryAddress> addresses = const [],
}) async {
  _usePhoneScreen(tester);
  final repo = FakeGamesRepository()
    ..competitions = [competition]
    ..addresses = addresses;
  if (board != null) repo.board = board;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gamesRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CompetitionScreen(competitionId: 'c1')),
    ),
  );
  await _frames(tester);
  return repo;
}

void main() {
  group('Competition screen', () {
    testWidgets('shows the prize, the required disclosures and the board', (
      tester,
    ) async {
      await _openCompetition(
        tester,
        _competition(me: _eligible),
        board: const CompetitionLeaderboard(
          status: 'live',
          isFinal: false,
          totalPlayers: 2,
          entries: [
            LeaderboardEntry(
              rank: 1,
              displayName: 'Sarah M.',
              score: 900,
              countryName: 'New Zealand',
              durationMs: 61000,
              status: 'provisional',
            ),
            LeaderboardEntry(
              rank: 2,
              displayName: 'Ben C.',
              score: 400,
              status: 'provisional',
              isMe: true,
            ),
          ],
        ),
      );

      expect(find.text('Play official attempt'), findsOneWidget);
      expect(find.textContaining('pre-funded by SendAgift'), findsOneWidget);
      expect(find.textContaining('Chance plays no part'), findsOneWidget);
      expect(find.text('2 of 3 left'), findsOneWidget);
      expect(find.textContaining('Free for now'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Sarah M.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sarah M.'), findsOneWidget);
      expect(find.text('Ben C. (you)'), findsOneWidget);
      expect(find.text('Provisional'), findsOneWidget);
    });

    testWidgets('guests are asked to sign in before playing', (tester) async {
      await _openCompetition(tester, _competition());
      expect(find.text('Sign in to play'), findsOneWidget);
      expect(find.text('Play official attempt'), findsNothing);
    });

    testWidgets('no attempts left means no play button', (tester) async {
      await _openCompetition(
        tester,
        _competition(
          me: const CompetitionMe(
            attemptsUsed: 3,
            attemptsRemaining: 0,
            eligible: true,
            bestScore: 1200,
            rank: 4,
          ),
        ),
      );
      expect(find.text('No attempts left'), findsOneWidget);
      expect(find.text('1200 · 4th place'), findsOneWidget);
    });

    testWidgets('an ineligible player is told why', (tester) async {
      await _openCompetition(
        tester,
        _competition(
          me: const CompetitionMe(
            attemptsUsed: 0,
            attemptsRemaining: 3,
            eligible: false,
            ineligibleReason: 'Verify your age to enter.',
          ),
        ),
      );
      expect(find.text('Not eligible'), findsOneWidget);
      expect(find.text('Verify your age to enter.'), findsWidgets);
    });

    testWidgets('a winner claims the prize to a saved address', (tester) async {
      final repo = await _openCompetition(
        tester,
        _competition(
          status: 'finalised',
          me: CompetitionMe(
            attemptsUsed: 2,
            attemptsRemaining: 1,
            eligible: true,
            win: MyWin(
              winnerId: 'w1',
              prizePosition: 1,
              status: 'validated',
              claimId: 'claim-1',
              claimStatus: 'pending',
              claimDeadlineAt: DateTime.now().add(const Duration(days: 10)),
            ),
          ),
          winners: const [
            PublicWinner(
              prizePosition: 1,
              displayName: 'Ben C.',
              countryName: 'New Zealand',
              score: 1400,
            ),
          ],
        ),
        addresses: const [
          DeliveryAddress(
            id: 'a1',
            line1: '1 Queen St',
            city: 'Auckland',
            isDefault: true,
          ),
        ],
      );

      expect(find.text('You won!'), findsOneWidget);
      await tester.tap(find.text('Claim your prize'));
      await _frames(tester);

      expect(find.text('1 Queen St'), findsOneWidget);
      // Claiming stays off until the terms are accepted.
      await tester.tap(find.text('Claim prize'));
      await _frames(tester, 200);
      expect(repo.claims, isEmpty);

      await tester.tap(
        find.text('I accept the prize terms and the official rules'),
      );
      await _frames(tester, 200);
      await tester.tap(find.text('Claim prize'));
      await _frames(tester);

      expect(repo.claims, ['a1']);
    });
  });

  group('Official attempt', () {
    testWidgets('uses an attempt, offers no restart, and submits on quit', (
      tester,
    ) async {
      _usePhoneScreen(tester);
      final repo = FakeGamesRepository()
        ..competitions = [_competition(me: _eligible)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gamesRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GamePlayScreen(
                          definition: gameDefinitions['2048']!,
                          competitionId: 'c1',
                        ),
                      ),
                    ),
                    child: const Text('launcher'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('launcher'));
      await _frames(tester);

      expect(repo.attemptCount, 1);
      expect(repo.startCount, 0, reason: 'no practice session is opened');
      expect(find.text('OFFICIAL ATTEMPT #1'), findsOneWidget);

      // Seed 'cafebabe' opens with both tiles off the left wall.
      await tester.fling(
        find.byType(AspectRatio).first,
        const Offset(-300, 0),
        1200,
      );
      await _frames(tester, 400);

      await tester.tap(find.byTooltip('Game menu'));
      await _frames(tester, 400);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Restart'), findsNothing);
      expect(find.textContaining('submits this attempt'), findsOneWidget);

      await tester.tap(find.text('Quit game'));
      await _frames(tester, 400);
      expect(
        find.textContaining('counts as one of your attempts'),
        findsOneWidget,
      );
      await tester.tap(find.text('Yes, quit'));
      await _frames(tester);

      expect(find.byType(GamePlayScreen), findsNothing);
      expect(repo.lastMoves, ['left']);
    });
  });
}
