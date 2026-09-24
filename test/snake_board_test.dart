import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/snake_game.dart';
import 'package:send_agift_mobile/features/games/presentation/game_controls.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/snake_board.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/tilt_3d.dart';

Future<SnakeGame> _pumpBoard(WidgetTester tester) async {
  final game = SnakeGame(seed: 'cafebabe');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: SnakeBoard(
              game: game,
              controls: GameControls(active: true, onChanged: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return game;
}

void main() {
  testWidgets('the grid is square and not tipped over', (tester) async {
    await _pumpBoard(tester);

    // Snake is played by judging the gap between the head and a wall. Under
    // a perspective tilt a square cell is drawn as a trapezoid, so the board
    // stays flat and the depth comes from how the snake is drawn instead.
    expect(
      find.descendant(
        of: find.byType(SnakeBoard),
        matching: find.byType(Tilt3D),
      ),
      findsNothing,
    );

    final grid = tester.getRect(
      find
          .descendant(
            of: find.byType(SnakeBoard),
            matching: find.byType(AspectRatio),
          )
          .first,
    );
    expect(grid.width, grid.height);
  });

  test('a segment is drawn between the cell it left and the one it entered', () {
    // A snake that jumped a whole cell per tick would only ever be drawn on
    // whole cells. Half way through a tick it has to be half way across.
    const grid = 15;
    final was = [5 * grid + 7, 5 * grid + 6, 5 * grid + 5];
    final now = [5 * grid + 8, 5 * grid + 7, 5 * grid + 6];

    Offset at(int i, double t) => snakeSegmentAt(
      body: now,
      wasBody: was,
      gridSize: grid,
      i: i,
      t: t,
    );

    expect(at(0, 0), const Offset(7, 5), reason: 'starts where it was');
    expect(at(0, 0.5), const Offset(7.5, 5), reason: 'half a cell across');
    expect(at(0, 1), const Offset(8, 5), reason: 'lands on the new cell');

    // Every segment travels, not just the head.
    expect(at(2, 0.5), const Offset(5.5, 5));
  });

  test('a new segment grows out of the tail rather than appearing', () {
    // The tick the snake eats, the body gets longer. The extra segment has no
    // previous cell of its own, so it comes out of the end of the tail.
    const grid = 15;
    final was = [20, 19];
    final now = [21, 20, 19];

    final tail = snakeSegmentAt(
      body: now,
      wasBody: was,
      gridSize: grid,
      i: 2,
      t: 0,
    );
    expect(tail, Offset((19 % grid).toDouble(), (19 ~/ grid).toDouble()));
  });

  testWidgets('the board keeps drawing as the round runs', (tester) async {
    final game = await _pumpBoard(tester);
    await tester.tap(find.byType(SnakeBoard));

    for (var i = 0; i < 20 && !game.isOver; i++) {
      await tester.pump(Duration(milliseconds: game.tickIntervalMs));
      expect(tester.takeException(), isNull);
    }
  });
}
