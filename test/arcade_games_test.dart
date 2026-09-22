import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/block_blast.dart';
import 'package:send_agift_mobile/features/games/domain/cricket_game.dart';
import 'package:send_agift_mobile/features/games/domain/hill_rider.dart';
import 'package:send_agift_mobile/features/games/domain/sling_shot.dart';

// Every log here was produced by a bot on the backend
// (`internal/games/arcade_golden_test.go`). Both engines must replay them
// identically, or honest scores would be rejected.

const _blockLog =
    '0:0:0,1:0:4,2:0:5,1:0:6,0:0:0,2:0:1,0:0:6,1:0:4,2:1:0,0:0:3,1:5:3,2:0:3,'
    '0:2:2,1:1:4,2:1:0,2:3:0,0:0:0,1:4:0,0:4:4,1:2:2,2:0:4,0:1:5,1:2:0,2:2:4,'
    '0:4:4,1:2:6,2:3:0,0:4:0,2:5:0,1:0:0,0:6:2,1:2:5,2:4:2,0:1:0,2:6:0,1:3:0,'
    '0:4:4,1:2:2,2:4:5,2:5:6,0:4:0,1:6:0,0:4:3,1:0:0,2:4:1,1:7:1,0:0:2,2:2:0,'
    '0:0:6,1:1:6';

const _cricketLog =
    '92:-80,251:-80,409:79,584:-80,740:-80,902:-80,1058:13,1378:-80,1523:-80,'
    '1686:13,1845:-80';

const _slingLog = '60:72,84:44,60:72,56:68,80:48,84:40,80:48,48:72,32:92';

const _hillLog =
    '0:g,70:n,90:g,160:n,180:g,250:n,270:g,285:b,300:g,340:n,360:g,430:n,'
    '450:g,520:n,540:g,585:b,600:g,610:n,630:g,700:n,720:g,790:n,810:g,880:n,'
    '900:g,970:n,990:g,1060:n,1080:g,1150:n,1170:g,1183:end';

void main() {
  group('Block Blast', () {
    test('cross-language golden', () {
      final game = BlockBlast(seed: 'cafebabe');
      for (final entry in _blockLog.split(',')) {
        final v = entry.split(':').map(int.parse).toList();
        expect(game.place(v[0], v[1], v[2]), isNotNull, reason: entry);
      }
      expect(game.score, 382);
      expect(game.isOver, isTrue);
      expect(game.lines, 18);
      expect(game.bestCombo, 2);
      expect(game.placed, 50);
      expect(game.hand, [-1, -1, 7]);
      expect(game.board, [
        19, 19, 5, 0, 2, 2, 14, 14, 0, 0, 5, 0, 0, 13, 9, 14, //
        23, 23, 5, 0, 23, 23, 9, 17, 24, 23, 23, 0, 8, 15, 9, 0,
        23, 18, 0, 18, 0, 20, 9, 20, 0, 18, 0, 0, 0, 0, 9, 0,
        0, 0, 0, 0, 16, 24, 0, 17, 22, 4, 0, 4, 0, 0, 0, 17,
      ]);
      expect(game.moves.join(','), _blockLog);
    });

    test('a piece that does not fit is refused and not logged', () {
      final game = BlockBlast(seed: 'cafebabe');
      expect(
        game.place(0, 7, 7),
        game.fits(game.hand[0], 7, 7) ? isNotNull : isNull,
      );
      expect(game.place(0, -1, 0), isNull);
      expect(game.place(5, 0, 0), isNull);
    });
  });

  group('Cricket', () {
    test('cross-language golden', () {
      final game = CricketGame(seed: 'cafebabe');
      expect(
        game.balls.toString(),
        '[{47 -1}, {44 1}, {48 1}, {59 -1}, {50 1}, {56 1}, {54 -1}, '
        '{50 -1}, {50 1}, {38 -1}, {47 1}, {38 0}]',
      );
      expect(game.fielders, [
        [79, 56, -32, 65, 69],
        [13, 69, 39, -66, -67],
      ]);

      for (final entry in _cricketLog.split(',')) {
        final v = entry.split(':').map(int.parse).toList();
        while (game.tick < v[0]) {
          game.advance();
        }
        expect(game.swing(v[1]), isNotNull, reason: entry);
      }
      while (!game.isOver) {
        game.advance();
      }
      expect(game.runs, 43);
      expect(game.fours, 3);
      expect(game.sixes, 5);
      expect(game.wickets, 2);
      expect(game.moves.join(','), _cricketLog);
    });

    test('no swing outside the window around the ball', () {
      final game = CricketGame(seed: 'cafebabe');
      expect(game.canSwing, isFalse);
      expect(game.swing(0), isNull);
      while (game.tick < game.arrival(0) - game.config.earlyTicks) {
        game.advance();
      }
      expect(game.canSwing, isTrue);
    });
  });

  group('Sling Shot', () {
    test('cross-language golden', () {
      final game = SlingShot(seed: 'cafebabe');
      for (final entry in _slingLog.split(',')) {
        final v = entry.split(':').map(int.parse).toList();
        expect(game.shoot(v[0], v[1]), isNotNull, reason: entry);
      }
      expect(game.score, 13250);
      expect(game.isOver, isTrue);
      expect(game.won, isTrue);
      expect(game.levelsCleared, 8);
      expect(game.targets, 14);
      expect(game.shots, 9);
      expect(
        [
          for (final b in game.blocks)
            if (b.alive) b.id,
        ],
        [8, 9, 10, 11, 12, 13, 14, 15],
      );
      expect(game.moves.join(','), _slingLog);
    });

    test('impossible pulls are refused', () {
      final game = SlingShot(seed: 'cafebabe');
      expect(game.shoot(0, 50), isNull);
      expect(game.shoot(80, 80), isNull);
      expect(game.moves, isEmpty);
    });
  });

  group('Hill Rider', () {
    test('cross-language golden', () {
      final entries = _hillLog.split(',');
      final end = int.parse(entries.last.split(':').first);
      final changes = <int, String>{
        for (final e in entries.take(entries.length - 1))
          int.parse(e.split(':')[0]): e.split(':')[1],
      };

      final game = HillRider(seed: 'cafebabe');
      for (var t = 0; t < end && !game.driveOver; t++) {
        final pedal = changes[t];
        if (pedal != null) game.setPedal(pedal);
        game.advance();
      }
      expect(game.crashed, isTrue);
      expect(game.score, 927);
      expect(game.distance, 892);
      expect(game.airTicks, 177);
      expect(game.cans, 3);
      expect(game.x * 16, 142734);
      expect(game.speed, 128);
      expect(game.fuel, 747);
      expect(game.moves.join(','), _hillLog);
    });

    test('the crash is shown before the round ends', () {
      final game = HillRider(seed: 'cafebabe');
      game.setPedal(HillPedal.gas);
      while (!game.driveOver) {
        game.advance();
      }
      expect(game.isOver, isFalse);
      for (var i = 0; i < 45; i++) {
        game.advance();
      }
      expect(game.isOver, isTrue);
    });
  });
}
