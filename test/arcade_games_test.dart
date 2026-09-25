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
    '0:g,20:b,30:g,50:b,60:g,70:b,80:g,110:b,120:g,140:b,150:g,170:b,180:g,'
    '210:b,220:g,230:n,240:g,250:b,260:g,270:b,280:g,290:n,300:g,310:b,320:g,'
    '330:n,340:g,450:n,460:b,470:g,510:b,570:n,580:g,590:b,600:g,610:b,620:n,'
    '630:g,640:b,650:g,660:n,670:g,680:b,690:g,700:n,710:b,720:n,730:g,810:n,'
    '820:g,830:b,840:g,880:n,890:g,920:n,930:g,940:n,950:g,980:b,990:n,'
    '1010:g,1020:n,1030:g,1040:b,1050:g,1070:b,1117:end';

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
      expect(game.score, 682);
      expect(game.distance, 651);
      expect(game.airTicks, 157);
      expect(game.cans, 2);
      expect(game.x * 16, 104190);
      expect(game.speed, 97);
      expect(game.fuel, 800);
      expect(game.moves.join(','), _hillLog);
    });

    test('the crash is shown before the round ends', () {
      final game = HillRider(seed: 'cafebabe');
      game.setPedal(HillPedal.gas);
      while (!game.driveOver) {
        game.advance();
      }
      expect(game.crashed, isTrue);
      expect(game.isOver, isFalse);
      var shown = 0;
      while (!game.isOver) {
        game.advance();
        shown++;
      }
      expect(shown, 90);
    });
  });
}
