import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/slide_puzzle.dart';
import 'package:send_agift_mobile/features/games/presentation/game_controls.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/puzzle_pictures.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/slide_board.dart';

Future<void> _pumpBoard(
  WidgetTester tester,
  SlidePuzzle puzzle, {
  // A fresh key when a test pumps a second board: without one Flutter reuses
  // the first board's state, picture already chosen, and the chooser never
  // comes back.
  Key? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: SlideBoard(
              key: key,
              game: puzzle,
              controls: GameControls(active: true, onChanged: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('the puzzle', () {
    test('is a 4x4 of fifteen tiles and a gap', () {
      final puzzle = SlidePuzzle(seed: 'cafebabe');
      expect(puzzle.size, 4);
      expect(puzzle.board, hasLength(16));
      expect(puzzle.board.where((v) => v == 0), hasLength(1));
    });

    test('only a finished puzzle scores, and fewer moves score more', () {
      // This is what puts finishers at the top of the leaderboard and orders
      // them by how few moves it took.
      final unsolved = SlidePuzzle(seed: 'cafebabe');
      expect(unsolved.solved, isFalse);
      expect(unsolved.score, 0);

      const optimal =
          'down,left,left,up,right,up,right,up,left,down,right,down,left,up,up,'
          'right,down,right,down,down,left,up,left,up,right,right,down,left,'
          'left,down,left,up,up,right,down,left,up,up';

      final quick = SlidePuzzle(seed: 'cafebabe');
      for (final move in optimal.split(',')) {
        quick.move(move);
      }

      // The same solve, but with a pair of wasted moves in front of it.
      final slow = SlidePuzzle(seed: 'cafebabe');
      slow.move('up');
      slow.move('down');
      for (final move in optimal.split(',')) {
        slow.move(move);
      }

      expect(quick.solved, isTrue);
      expect(slow.solved, isTrue);
      expect(
        slow.score,
        lessThan(quick.score),
        reason: 'wasting moves must cost the player something',
      );
    });

    test('a good solve is not flattened onto the score floor', () {
      // A 4x4 takes a few hundred moves played well. If the floor arrived
      // before then, every ordinary solve would tie and the leaderboard
      // would stop telling them apart.
      const config = SlideConfig();
      final floorAt = (config.solveBase - config.solvedMinScore) ~/
          config.movePenalty;
      expect(
        floorAt,
        greaterThan(500),
        reason: 'the score bottoms out after only $floorAt moves',
      );
    });
  });

  group('the board', () {
    testWidgets('opens on the picture chooser and plays nothing yet', (
      tester,
    ) async {
      final puzzle = SlidePuzzle(seed: 'cafebabe');
      await _pumpBoard(tester, puzzle);

      expect(find.text('Pick your picture'), findsOneWidget);
      for (final picture in puzzlePictures) {
        expect(find.text(picture.name), findsOneWidget);
      }
      expect(puzzle.moves, isEmpty);
    });

    testWidgets('there are several pictures to choose between', (tester) async {
      await _pumpBoard(tester, SlidePuzzle(seed: 'cafebabe'));
      expect(puzzlePictures.length, greaterThanOrEqualTo(3));
      expect(
        puzzlePictures.map((p) => p.name).toSet(),
        hasLength(puzzlePictures.length),
      );
    });

    testWidgets('picking a picture deals the tiles', (tester) async {
      final puzzle = SlidePuzzle(seed: 'cafebabe');
      await _pumpBoard(tester, puzzle);

      await tester.tap(find.text('Seaside'));
      await tester.pumpAndSettle();

      expect(find.text('Pick your picture'), findsNothing);
      // Fifteen tiles, each numbered so a piece can be placed.
      for (var value = 1; value <= 15; value++) {
        expect(
          find.descendant(
            of: find.byType(SlideBoard),
            matching: find.text('$value'),
          ),
          findsOneWidget,
          reason: 'tile $value is missing',
        );
      }
    });

    testWidgets('the picture does not change the puzzle', (tester) async {
      // The scramble comes from the server's seed. Two players on one seed
      // must solve the same board whichever picture they chose.
      final first = SlidePuzzle(seed: 'cafebabe');
      await _pumpBoard(tester, first, key: const ValueKey('first'));
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      final second = SlidePuzzle(seed: 'cafebabe');
      await _pumpBoard(tester, second, key: const ValueKey('second'));
      await tester.tap(find.text('Night sky'));
      await tester.pumpAndSettle();

      expect(second.board, first.board);
    });

    testWidgets('tapping a tile in line with the gap slides it', (
      tester,
    ) async {
      final puzzle = SlidePuzzle(seed: 'cafebabe');
      await _pumpBoard(tester, puzzle);
      await tester.tap(find.text('Bouquet'));
      await tester.pumpAndSettle();

      // The tile left of the gap: tapping it slides it right into the space.
      final value = puzzle.board[puzzle.blank - 1];
      await tester.tap(
        find.descendant(
          of: find.byType(SlideBoard),
          matching: find.text('$value'),
        ),
      );
      await tester.pumpAndSettle();

      expect(puzzle.moves, ['right']);
    });
  });
}
