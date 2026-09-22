import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/doodle_jump.dart';
import 'package:send_agift_mobile/features/games/presentation/game_controls.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/doodle_board.dart';

const _config = DoodleConfig();

Future<int> _pumpBoard(
  WidgetTester tester,
  DoodleJump game, {
  VoidCallback? onChanged,
}) async {
  var changes = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        // The drifting motes never stop, so a test that waits for the tree to
        // settle would wait forever. Reduced motion parks them, which is the
        // same path a player with animations turned off gets.
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: DoodleBoard(
            game: game,
            controls: GameControls(
              active: true,
              onChanged: () {
                changes++;
                onChanged?.call();
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return changes;
}

/// Taps the lane strip, which is laid out flat over the board.
Future<void> _tapLane(WidgetTester tester, int lane) async {
  final board = tester.getRect(find.byKey(doodleSurfaceKey));
  final width = board.width / _config.lanes;
  await tester.tapAt(
    Offset(board.left + width * (lane + 0.5), board.center.dy),
  );
  await tester.pump();
}

void main() {
  testWidgets('hopping to a reachable lane climbs the tower', (tester) async {
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    await _pumpBoard(tester, game);

    // Land on a lane the next rung actually has, so this tests the climb
    // rather than a fall.
    final next = game.platforms[game.height + 1];
    final target = game.canReach(next.lane) ? next.lane : next.alt;
    expect(game.canReach(target), isTrue);

    await _tapLane(tester, target);
    await tester.pumpAndSettle();

    expect(game.height, greaterThan(0));
    expect(game.moves, ['$target']);
  });

  testWidgets('a lane out of reach is refused', (tester) async {
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    await _pumpBoard(tester, game);

    final far = List.generate(
      _config.lanes,
      (i) => i,
    ).firstWhere((lane) => !game.canReach(lane));

    await _tapLane(tester, far);
    await tester.pumpAndSettle();

    expect(game.moves, isEmpty, reason: 'an unreachable lane must not log');
    expect(game.height, 0);
  });

  testWidgets('a hop that misses still reports the fall', (tester) async {
    // hop() returns false when the jumper misses, but the round is over and
    // the screen only learns that through onChanged. Returning early there
    // would leave the game looking frozen on a fall.
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    var changes = 0;
    await _pumpBoard(tester, game, onChanged: () => changes++);

    final next = game.platforms[game.height + 1];
    final miss = List.generate(_config.lanes, (i) => i).firstWhere(
      (lane) => game.canReach(lane) && !next.has(lane),
      orElse: () => -1,
    );
    if (miss < 0) return; // this deal offers no miss from the opening rung

    await _tapLane(tester, miss);
    await tester.pumpAndSettle();

    expect(game.fell, isTrue);
    expect(game.isOver, isTrue);
    expect(changes, greaterThan(0), reason: 'the fall was never reported');
  });

  testWidgets('the climb is animated rather than snapping a rung at a time', (
    tester,
  ) async {
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    await _pumpBoard(tester, game);

    final next = game.platforms[game.height + 1];
    final target = game.canReach(next.lane) ? next.lane : next.alt;

    await _tapLane(tester, target);
    // Part-way through the hop the board is still rebuilding: a tower that
    // snapped straight to the new rung would have settled by now.
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the board lays out on a small phone without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1334); // iPhone SE
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final game = DoodleJump(seed: 'cafebabe', config: _config);
    await _pumpBoard(tester, game);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the climber is drawn, not assembled from boxes', (tester) async {
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    await _pumpBoard(tester, game);

    // A painted figure, so the limbs can move with the jump. It has to paint
    // cleanly at whatever size the lane gives it, mid-jump included.
    expect(find.byType(CustomPaint), findsWidgets);

    final next = game.platforms[game.height + 1];
    final target = game.canReach(next.lane) ? next.lane : next.alt;
    await _tapLane(tester, target);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
  });

  testWidgets('a spring carries the climber its full lift, and takes longer', (
    tester,
  ) async {
    // The engine bumps height an extra rung for a spring, so after the hop
    // its height has already moved past the spring to the rung above it. A
    // board reading the spring off the landing rung sees a plain ledge and
    // never plays the launch at all.
    final game = DoodleJump(seed: 'cafebabe', config: _config);

    // Climb until the next rung up is a spring.
    var guard = 0;
    while (!game.isOver && guard++ < 200) {
      final next = game.platforms[game.height + 1];
      if (next.spring && game.canReach(next.lane)) break;
      final target = game.canReach(next.lane) ? next.lane : next.alt;
      if (target < 0 || !game.canReach(target)) break;
      game.hop(target);
    }
    final spring = game.platforms[game.height + 1];
    // Not a skip: if this deal never puts a spring in reach the test is not
    // testing anything, and saying so beats passing quietly.
    expect(spring.spring, isTrue, reason: 'no spring came up within reach');
    expect(game.isOver, isFalse);

    final before = game.height;
    final springs = game.springs;
    await _pumpBoard(tester, game);
    await _tapLane(tester, spring.lane);

    // Climbing several rungs in one hop is what a spring does, and what the
    // board reads the launch from. Three ledges by default: the spring and
    // the two it clears.
    expect(game.height - before, _config.springLift);
    expect(_config.springLift, greaterThanOrEqualTo(3));
    expect(game.springs, springs + 1);

    // A plain hop has settled by 300ms; being flung takes noticeably longer.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.binding.hasScheduledFrame,
      isTrue,
      reason: 'the launch was over as quickly as an ordinary hop',
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finished round stops taking hops', (tester) async {
    final game = DoodleJump(seed: 'cafebabe', config: _config);
    // Walk it off the tower.
    while (!game.isOver) {
      final next = game.platforms[game.height + 1];
      final miss = List.generate(_config.lanes, (i) => i).firstWhere(
        (lane) => game.canReach(lane) && !next.has(lane),
        orElse: () => -1,
      );
      if (miss < 0) {
        game.hop(next.has(game.lane) ? game.lane : next.lane);
        continue;
      }
      game.hop(miss);
    }

    await _pumpBoard(tester, game);
    final logged = game.moves.length;
    await _tapLane(tester, game.lane);
    await tester.pumpAndSettle();

    expect(game.moves.length, logged, reason: 'a finished round still moved');
  });
}
