import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/basketball_game.dart';

/// Produced by a bot on the backend (`internal/games/sports_golden_test.go`,
/// TestBasketballCrossLanguageGolden). Both engines must replay it identically.
const _goldenLog =
    '5:0:40,32:0:85,59:0:75,86:0:55,113:9:40,140:-13:85,167:8:70,194:11:60,'
    '221:-10:40,248:-16:85,275:0:70,302:34:55,329:-3:45,356:-28:85,383:-3:70,'
    '410:-27:55,437:72:40,464:-33:90,491:3:70,518:25:55,545:-20:40,572:15:85,'
    '599:5:70,626:5:55,653:17:40,680:-35:85,707:52:70,734:-70:60,761:-8:40,'
    '788:40:85,815:-58:70,842:65:55,869:-47:45,896:-46:85';

void _advanceTo(BasketballGame game, int tick) {
  while (game.tick < tick) {
    game.advance();
  }
}

void main() {
  test('cross-language golden: replays exactly like the Go engine', () {
    final game = BasketballGame(seed: 'cafebabe');
    for (final entry in _goldenLog.split(',')) {
      final v = entry.split(':').map(int.parse).toList();
      _advanceTo(game, v[0]);
      expect(game.shoot(v[1], v[2]), isNotNull, reason: entry);
    }

    expect(game.score, 124);
    expect(game.makes, 29);
    expect(game.shots, 34);
    expect(game.swishes, 23);
    expect(game.bestStreak, 5);
    expect(game.distance, 2);
    expect(game.level, 7);
    // And the app would submit exactly the log the server replayed.
    expect(game.moves.join(','), _goldenLog);
  });

  test('a dead-centre shot swishes', () {
    final game = BasketballGame(seed: 'cafebabe');
    final shot = game.shoot(
      game.hoopX(game.config.flightTicks),
      BasketballGame.requiredPower(game.distance),
    )!;
    expect(shot.made, isTrue);
    expect(shot.swish, isTrue);
  });

  test('no second ball until the first has landed', () {
    final game = BasketballGame(seed: 'cafebabe');
    expect(game.shoot(0, 50), isNotNull);
    _advanceTo(game, 19);
    expect(game.canShoot, isFalse);
    expect(game.shoot(0, 50), isNull);
    expect(game.moves, hasLength(1));
    game.advance();
    expect(game.canShoot, isTrue);
  });

  test('the score settles when the ball drops, not when it is thrown', () {
    final game = BasketballGame(seed: 'cafebabe');
    game.shoot(game.hoopX(14), BasketballGame.requiredPower(game.distance));
    expect(game.score, greaterThan(0));
    expect(game.settledScore, 0);
    _advanceTo(game, 14);
    expect(game.settledScore, game.score);
  });

  test('the round ends at the buzzer, once the last shot has landed', () {
    final game = BasketballGame(seed: 'cafebabe');
    while (!game.isOver) {
      game.advance();
    }
    expect(game.tick, 900 + 14);
    expect(game.canShoot, isFalse);
  });

  test('the hoop stays still until the first level', () {
    final game = BasketballGame(seed: 'cafebabe');
    for (var t = 0; t < 200; t++) {
      expect(game.hoopX(t), 0);
    }
    expect(game.hoopXFor(10, 1), isNot(equals(game.hoopXFor(40, 1))));
  });

  test('config parsing falls back exactly like the backend', () {
    final config = BasketballConfig.fromJson(const {
      'flight_ticks': 30,
      'shot_cooldown_ticks': 10,
    });
    expect(config.shotCooldownTicks, 30, reason: 'cooldown covers the flight');
    expect(BasketballConfig.fromJson(const {}).roundTicks, 900);
  });
}
