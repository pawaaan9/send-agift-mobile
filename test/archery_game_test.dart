import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/archery_game.dart';

/// Produced by a bot on the backend (`internal/games/sports_golden_test.go`,
/// TestArcheryCrossLanguageGolden). Both engines must replay it identically.
const _goldenLog =
    '40:-9:8,87:25:-11,134:-18:-2,181:-8:36,228:32:11,275:-24:-3,322:31:-1,'
    '369:13:-3,416:-6:-9,463:83:45';
const _goldenWinds = [16, -13, 16, 19, -12, -2, -14, 20, 20, -11];

void _advanceTo(ArcheryGame game, int tick) {
  while (game.tick < tick) {
    game.advance();
  }
}

void main() {
  test('cross-language golden: replays exactly like the Go engine', () {
    final game = ArcheryGame(seed: 'cafebabe');
    final entries = _goldenLog.split(',');
    for (var i = 0; i < entries.length; i++) {
      final v = entries[i].split(':').map(int.parse).toList();
      _advanceTo(game, v[0]);
      expect(game.wind, _goldenWinds[i], reason: 'wind for arrow $i');
      expect(game.shoot(v[1], v[2]), isNotNull, reason: entries[i]);
    }

    expect(game.score, 83);
    expect(game.tens, 5);
    expect(game.xs, 3);
    expect(game.arrowsShot, 10);
    expect(game.moves.join(','), _goldenLog);
  });

  test('rings score 10 in the middle down to 0 off the target', () {
    expect(ArcheryGame.pointsFor(0, 0, 10), 10);
    expect(ArcheryGame.pointsFor(10, 0, 10), 10);
    expect(ArcheryGame.pointsFor(11, 0, 10), 9);
    expect(ArcheryGame.pointsFor(0, -20, 10), 9);
    expect(ArcheryGame.pointsFor(60, 80, 10), 1);
    expect(ArcheryGame.pointsFor(61, 80, 10), 0);
  });

  test('compensating for the wind and the sway hits the X', () {
    final game = ArcheryGame(seed: 'cafebabe');
    _advanceTo(game, 40);
    final (sx, sy) = game.sway(40);
    final arrow = game.shoot(-sx - game.wind, -sy)!;
    expect(arrow.points, 10);
    expect(arrow.inner, isTrue);
  });

  test('the next arrow is only ready after reloading', () {
    final game = ArcheryGame(seed: 'cafebabe');
    expect(game.shoot(0, 0), isNotNull);
    _advanceTo(game, 29);
    expect(game.canShoot, isFalse);
    expect(game.shoot(0, 0), isNull);
    game.advance();
    expect(game.canShoot, isTrue);
  });

  test('the round ends once the tenth arrow has landed', () {
    final game = ArcheryGame(seed: 'cafebabe');
    for (var i = 0; i < 10; i++) {
      _advanceTo(game, i * 30);
      game.shoot(0, 0);
    }
    expect(game.isOver, isFalse, reason: 'the last arrow is still flying');
    _advanceTo(game, 9 * 30 + 30);
    expect(game.isOver, isTrue);
  });

  test('config parsing falls back exactly like the backend', () {
    expect(ArcheryConfig.fromJson(const {'sway_period_x': 45}).swayPeriodX, 46);
    expect(ArcheryConfig.fromJson(const {}).arrows, 10);
  });
}
