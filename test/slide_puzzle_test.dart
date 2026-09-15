import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/game_engine.dart';
import 'package:send_agift_mobile/features/games/domain/slide_puzzle.dart';

void main() {
  test('cross-language golden: same scramble and solution as the Go engine', () {
    // Mirrors TestSlideCrossLanguageGolden in internal/games/slide_test.go.
    final puzzle = SlidePuzzle(seed: 'cafebabe');
    expect(puzzle.board, [1, 3, 6, 5, 0, 7, 2, 4, 8]);

    const solution =
        'left,down,right,right,up,up,left,down,right,down,left,up,right,up,left,left';
    for (final move in solution.split(',')) {
      expect(puzzle.move(move), isTrue, reason: 'move $move should be legal');
    }

    expect(puzzle.solved, isTrue);
    expect(puzzle.score, 4680);
    expect(puzzle.moves.join(','), solution);
  });

  test('a scramble is a valid, unsolved permutation', () {
    final puzzle = SlidePuzzle(seed: 'a1b2c3d4');
    expect(puzzle.solved, isFalse);
    expect(puzzle.moves, isEmpty, reason: 'scrambling is not player moves');
    expect([...puzzle.board]..sort(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    expect(SlidePuzzle(seed: 'a1b2c3d4').board, puzzle.board);
  });

  test('tapping a tile further along the line slides every tile between', () {
    final puzzle = SlidePuzzle(seed: 'cafebabe');
    // Gap at index 4 (centre). Index 3 is left of it, index 5 right of it.
    expect(puzzle.blank, 4);

    expect(puzzle.moveTileAt(3), isTrue);
    expect(puzzle.moves, [Move.right]);
    expect(puzzle.blank, 3);

    // Gap now at the left of the middle row; tapping the far right tile
    // pushes two tiles left.
    expect(puzzle.moveTileAt(5), isTrue);
    expect(puzzle.moves, [Move.right, Move.left, Move.left]);
    expect(puzzle.blank, 5);
  });

  test('tapping a tile out of line with the gap does nothing', () {
    final puzzle = SlidePuzzle(seed: 'cafebabe');
    expect(puzzle.moveTileAt(0), isFalse);
    expect(puzzle.moves, isEmpty);
  });

  test('an unsolved board scores nothing', () {
    final puzzle = SlidePuzzle(seed: 'cafebabe');
    puzzle.move(Move.left);
    expect(puzzle.score, 0);
  });

  test('config parsing falls back exactly like the backend', () {
    final config = SlideConfig.fromJson(const {'size': 1});
    expect(config.size, 3);
    // Missing penalty is 0 on the server, so it must be here too.
    expect(config.movePenalty, 0);
  });
}
