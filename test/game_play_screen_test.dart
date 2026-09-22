import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/domain/slide_puzzle.dart';
import 'package:send_agift_mobile/features/games/presentation/game_definitions.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/game_play_screen.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/archery_range.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/basketball_court.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/cricket_pitch.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/slide_board.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/stack_tower_board.dart';

import 'support/fake_games_repository.dart';

/// The game screens animate forever (the living backdrop), so frames are
/// pumped for a fixed time instead of pumpAndSettle.
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

/// Opens the game from a launcher page so quitting has somewhere to go back to.
Future<FakeGamesRepository> _openGame(WidgetTester tester, String slug) async {
  _usePhoneScreen(tester);
  final repo = FakeGamesRepository();
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
                    builder: (_) =>
                        GamePlayScreen(definition: gameDefinitions[slug]!),
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
  return repo;
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Game menu'));
  await _frames(tester, 400);
}

/// Quits from the open game menu, confirming in the pop-up.
Future<void> _quitGame(WidgetTester tester) async {
  await tester.tap(find.text('Quit game'));
  await _frames(tester, 400);
  await tester.tap(find.text('Yes, quit'));
}

Future<void> _swipe(WidgetTester tester, Offset delta) async {
  await tester.fling(find.byType(AspectRatio).first, delta, 1200);
  await _frames(tester, 400);
}

void main() {
  group('2048', () {
    testWidgets('opens full-screen with a seeded board', (tester) async {
      final repo = await _openGame(tester, '2048');

      expect(repo.startCount, 1);
      expect(find.byType(GamePlayScreen), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('BEST TILE'), findsOneWidget);
    });

    testWidgets('a swipe moves the board and counts the move', (tester) async {
      await _openGame(tester, '2048');

      // Seed 'cafebabe' opens with both tiles off the left wall.
      await _swipe(tester, const Offset(-300, 0));

      final movesChip = find.ancestor(
        of: find.text('MOVES'),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: movesChip.first, matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('quit from the game menu banks the run and closes the window', (
      tester,
    ) async {
      final repo = await _openGame(tester, '2048');
      await _swipe(tester, const Offset(-300, 0));
      await _swipe(tester, const Offset(0, -300));

      await _openMenu(tester);
      expect(find.text('Paused'), findsOneWidget);

      await _quitGame(tester);
      await _frames(tester);

      expect(find.byType(GamePlayScreen), findsNothing);
      expect(find.text('launcher'), findsOneWidget);
      expect(repo.lastMoves, ['left', 'up']);
    });

    testWidgets('quitting before playing sends nothing', (tester) async {
      final repo = await _openGame(tester, '2048');
      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);

      expect(find.byType(GamePlayScreen), findsNothing);
      expect(repo.submissions, isEmpty);
    });

    testWidgets('the back gesture opens the menu instead of leaving', (
      tester,
    ) async {
      await _openGame(tester, '2048');

      await tester.binding.handlePopRoute();
      await _frames(tester, 400);
      expect(find.byType(GamePlayScreen), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await _frames(tester, 400);
      expect(find.text('Paused'), findsNothing);
    });

    testWidgets('restart banks the old run and opens a new session', (
      tester,
    ) async {
      final repo = await _openGame(tester, '2048');
      await _swipe(tester, const Offset(-300, 0));

      await _openMenu(tester);
      await tester.tap(find.text('Restart'));
      await _frames(tester);

      expect(repo.startCount, 2);
      expect(repo.lastMoves, ['left']);
    });
  });

  group('Slide Puzzle', () {
    testWidgets('solving submits the moves and shows the result', (
      tester,
    ) async {
      final repo = await _openGame(tester, 'slide-puzzle');

      // Solve it by tapping tiles, working out each tap from a twin engine
      // on the same seed.
      final twin = SlidePuzzle(seed: 'cafebabe');
      const solution =
          'left,down,right,right,up,up,left,down,right,down,left,up,right,up,left,left';
      for (final move in solution.split(',')) {
        final (dx, dy) = switch (move) {
          'up' => (0, -1),
          'down' => (0, 1),
          'left' => (-1, 0),
          _ => (1, 0),
        };
        final tile = (twin.blank ~/ 3 - dy) * 3 + (twin.blank % 3 - dx);
        final value = twin.board[tile];
        twin.move(move);

        // Scoped to the board: the stats strip shows numbers too.
        await tester.tap(
          find.descendant(
            of: find.byType(SlideBoard),
            matching: find.text('$value'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      await _frames(tester, 1200);

      expect(repo.lastMoves?.join(','), solution);
      expect(find.text('VERIFIED SCORE'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
    });
  });

  group('Snake', () {
    testWidgets('waits for the player, runs on ticks, and pauses', (
      tester,
    ) async {
      final repo = await _openGame(tester, 'snake');
      expect(find.text('Swipe or tap to start'), findsOneWidget);

      // Nothing moves until the player starts.
      await _frames(tester, 1000);
      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);
      expect(repo.submissions, isEmpty, reason: 'no ticks were played');
    });

    testWidgets('quitting mid-run submits the tick log with its end marker', (
      tester,
    ) async {
      final repo = await _openGame(tester, 'snake');

      await tester.tap(find.text('Swipe or tap to start'));
      await _frames(tester, 500); // ~3 ticks at 160ms
      await tester.tap(find.byTooltip('Up'));
      await _frames(tester, 400);

      // Paused: the clock must stop.
      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);

      final moves = repo.lastMoves!;
      expect(moves.last, endsWith(':end'));
      expect(moves.where((m) => m.endsWith(':up')), hasLength(1));
      final ticks = int.parse(moves.last.split(':').first);
      expect(ticks, greaterThan(2));
    });
  });

  group('Basketball', () {
    testWidgets('a swipe up shoots, and quitting banks the shot', (
      tester,
    ) async {
      final repo = await _openGame(tester, 'basketball');
      expect(find.text('Swipe up from the ball to shoot'), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);

      await tester.drag(find.byType(BasketballCourt), const Offset(0, -260));
      await _frames(tester, 400);
      expect(find.text('Swipe up from the ball to shoot'), findsNothing);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);

      expect(repo.lastMoves, hasLength(1));
      expect(repo.lastMoves!.single, matches(RegExp(r'^\d+:0:\d+$')));
    });
  });

  group('Stack Tower', () {
    testWidgets('tap to start, tap to drop', (tester) async {
      final repo = await _openGame(tester, 'stack-tower');
      expect(find.text('Tap to start'), findsOneWidget);

      await tester.tap(find.byType(StackTowerBoard));
      await _frames(tester, 1000);
      await tester.tap(find.byType(StackTowerBoard));
      await _frames(tester, 300);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);

      expect(repo.lastMoves, hasLength(1));
      expect(int.parse(repo.lastMoves!.single), greaterThan(0));
    });
  });

  group('Game menu', () {
    testWidgets('quitting asks first, and Keep playing goes back', (
      tester,
    ) async {
      final repo = await _openGame(tester, '2048');
      await _swipe(tester, const Offset(-300, 0));
      await _openMenu(tester);

      await tester.tap(find.text('Quit game'));
      await _frames(tester, 400);
      expect(find.text('Leave the game?'), findsOneWidget);
      expect(find.textContaining('will be saved'), findsOneWidget);

      await tester.tap(find.text('Keep playing'));
      await _frames(tester, 400);
      expect(find.text('Leave the game?'), findsNothing);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.byType(GamePlayScreen), findsOneWidget);
      expect(repo.submissions, isEmpty, reason: 'nothing was banked');
    });

    testWidgets('the back gesture closes the pop-up instead of leaving', (
      tester,
    ) async {
      await _openGame(tester, '2048');
      await _openMenu(tester);
      await tester.tap(find.text('Quit game'));
      await _frames(tester, 400);
      expect(find.text('Nothing has been played yet.'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _frames(tester, 400);
      expect(find.text('Leave the game?'), findsNothing);
      expect(find.byType(GamePlayScreen), findsOneWidget);
    });

    testWidgets('opens the leaderboard without leaving the game', (
      tester,
    ) async {
      await _openGame(tester, '2048');
      await _openMenu(tester);
      await tester.tap(find.text('Leaderboard'));
      await _frames(tester, 600);

      expect(
        find.text('No scores yet. Be the first on the board.'),
        findsOneWidget,
      );
      expect(find.byType(GamePlayScreen), findsOneWidget);
    });
  });

  group('Block Blast', () {
    testWidgets('tap a piece, then a square, to place it', (tester) async {
      final repo = await _openGame(tester, 'block-blast');
      await tester.tap(find.byKey(const ValueKey('block-blast-slot-0')));
      await _frames(tester, 200);

      final board = tester.getRect(
        find.byKey(const ValueKey('block-blast-board')),
      );
      final cell = (board.width - 16) / 8;
      await tester.tapAt(board.topLeft + Offset(8 + cell / 2, 8 + cell / 2));
      await _frames(tester, 400);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);
      expect(repo.lastMoves, ['0:0:0']);
    });
  });

  group('Cricket', () {
    testWidgets('tap to start, then tap to swing at the ball', (tester) async {
      final repo = await _openGame(tester, 'cricket');
      await tester.tap(find.text('Tap to start'));
      // Ball one reaches the bat at tick 92 for this seed; its window opens
      // at 80.
      await _frames(tester, 1700);
      await tester.tap(find.byType(CricketPitch));
      await _frames(tester, 200);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);
      expect(repo.lastMoves, hasLength(1));
      expect(repo.lastMoves!.single, matches(RegExp(r'^\d+:-?\d+$')));
    });
  });

  group('Sling Shot', () {
    testWidgets('drag back and let go to fire', (tester) async {
      final repo = await _openGame(tester, 'sling-shot');
      await tester.drag(
        find.byKey(const ValueKey('sling-area')),
        const Offset(-120, 60),
      );
      await _frames(tester, 300);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);
      expect(repo.lastMoves, hasLength(1));
      expect(repo.lastMoves!.single, matches(RegExp(r'^\d+:-?\d+$')));
    });
  });

  group('Hill Rider', () {
    testWidgets('hold gas to drive, let go to coast', (tester) async {
      final repo = await _openGame(tester, 'hill-rider');
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hill-gas'))),
      );
      await _frames(tester, 600);
      await gesture.up();
      await _frames(tester, 200);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);
      final moves = repo.lastMoves!;
      expect(moves.first, '0:g');
      expect(moves[1], endsWith(':n'));
      expect(moves.last, endsWith(':end'));
    });
  });

  group('Archery', () {
    testWidgets('drag to aim, let go to shoot', (tester) async {
      final repo = await _openGame(tester, 'archery');
      expect(find.text('Arrow 1 of 10'), findsOneWidget);

      await tester.drag(find.byType(ArcheryRange), const Offset(30, -40));
      await _frames(tester, 300);
      expect(find.text('Arrow 2 of 10'), findsOneWidget);

      await _openMenu(tester);
      await _quitGame(tester);
      await _frames(tester);

      expect(repo.lastMoves, hasLength(1));
      expect(repo.lastMoves!.single, matches(RegExp(r'^\d+:-?\d+:-?\d+$')));
    });
  });
}
