import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/stack_tower.dart';

/// Produced by a bot on the backend (`internal/games/sports_golden_test.go`,
/// TestStackCrossLanguageGolden). Both engines must replay it identically.
const _goldenLog = '38,75,111,149,183,215,247,281,311,340,368,398,424,449,496';

void _advanceTo(StackTower game, int tick) {
  while (game.tick < tick) {
    game.advance();
  }
}

/// The tick in the next swing where the floor sits most squarely.
int _bestTick(StackTower game) {
  var best = game.tick + 1;
  var bestOff = 1 << 30;
  for (var t = game.tick + 1; t <= game.tick + game.period; t++) {
    final off = game.offsetAt(t).abs();
    if (off < bestOff) {
      best = t;
      bestOff = off;
    }
  }
  return best;
}

void main() {
  test('cross-language golden: replays exactly like the Go engine', () {
    final game = StackTower(seed: 'cafebabe');
    for (final entry in _goldenLog.split(',')) {
      _advanceTo(game, int.parse(entry));
      expect(game.drop(), isNotNull, reason: entry);
    }

    expect(game.score, 245);
    expect(game.floorCount, 14);
    expect(game.perfects, 11);
    expect(game.bestStreak, 3);
    expect(game.fell, isTrue);
    expect(game.top, const StackBlock(-50, 50, -50, 6));
    expect(game.moves.join(','), _goldenLog);
  });

  test('a perfect drop keeps the full width', () {
    final game = StackTower(seed: 'cafebabe');
    _advanceTo(game, _bestTick(game));
    final drop = game.drop()!;
    expect(drop.perfect, isTrue);
    expect(drop.cut, isNull);
    expect(game.top, game.floors.first);
  });

  test('an overhang is sliced off and falls', () {
    final game = StackTower(seed: 'cafebabe');
    _advanceTo(game, _bestTick(game) + 5);
    final drop = game.drop()!;
    expect(drop.perfect, isFalse);
    expect(drop.cut, isNotNull);
    expect(game.top.width + drop.offset.abs(), 100);
  });

  test('a second tap inside the same tick is ignored', () {
    final game = StackTower(seed: 'cafebabe');
    _advanceTo(game, 40);
    expect(game.drop(), isNotNull);
    expect(game.drop(), isNull);
    expect(game.moves, hasLength(1));
  });

  test('missing the tower ends the game, after a moment to watch it fall', () {
    final game = StackTower(seed: 'cafebabe');
    _advanceTo(game, game.period ~/ 2);
    final drop = game.drop()!;
    expect(drop.fell, isTrue);
    expect(game.isOver, isFalse);
    for (var i = 0; i < 30; i++) {
      game.advance();
    }
    expect(game.isOver, isTrue);
    expect(game.drop(), isNull);
  });

  test('config parsing falls back exactly like the backend', () {
    final config = StackConfig.fromJson(const {
      'start_period_ticks': 151,
      'min_period_ticks': 65,
    });
    expect(config.minPeriodTicks, 66, reason: 'periods are made even');
    expect(config.startPeriodTicks, 152);
    expect(StackConfig.fromJson(const {}).travel, 130);
  });
}
