import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/presentation/game_controls.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/game_hud.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// What [over] looks like once laid on [under].
Color _composite(Color over, Color under) {
  final a = over.a;
  return Color.from(
    alpha: 1,
    red: over.r * a + under.r * (1 - a),
    green: over.g * a + under.g * (1 - a),
    blue: over.b * a + under.b * (1 - a),
  );
}

void main() {
  test('a panel keeps its white text readable on any backdrop', () {
    // These float over whatever the game paints. Archery's sky is almost
    // white at the top, and a pale panel there left the score invisible.
    final panel = glassDecoration().color!;

    const backdrops = {
      'archery sky': Color(0xFFBDEBFF),
      'archery sun': Color(0xFFFFF8E1),
      'basketball court': Color(0xFFE2A76F),
      'snake board': Color(0xFF031B15),
      'doodle sky': Color(0xFF10B981),
    };

    for (final entry in backdrops.entries) {
      final seen = _composite(panel, entry.value);
      final contrast = 1.05 / (_luminance(seen) + 0.05);
      expect(
        contrast,
        greaterThanOrEqualTo(3.0),
        reason: 'white on the panel over ${entry.key} is only '
            '${contrast.toStringAsFixed(2)}:1',
      );
    }
  });

  testWidgets('the stats row still shows its numbers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameStatsRow(
            stats: [GameStat('Score', 12), GameStat('Arrows', 10)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('ARROWS'), findsOneWidget);
  });
}
