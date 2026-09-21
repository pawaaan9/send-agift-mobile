import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/presentation/widgets/game_art.dart';

/// Every slug the game list can show. A painter that throws only does so when
/// it is actually painted, so each one is rendered rather than constructed.
const _slugs = [
  '2048',
  'snake',
  'basketball',
  'stack-tower',
  'archery',
  'cricket',
  'block-blast',
  'sling-shot',
  'hill-rider',
  'slide-puzzle',
  'memory-match',
  'whack-a-mole',
  'bubble-shooter',
  'tower-blocks',
  'fruit-slice',
  'doodle-jump',
];

Future<void> _paint(WidgetTester tester, String slug, double size) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: GameArt(slug: slug, size: size)),
      ),
    ),
  );
  expect(tester.takeException(), isNull, reason: '$slug failed at ${size}px');
}

void main() {
  testWidgets('every game paints at badge and watermark size', (tester) async {
    for (final slug in _slugs) {
      await _paint(tester, slug, 38);
      await _paint(tester, slug, 130);
    }
  });

  testWidgets('a game this build has no drawing for still paints', (
    tester,
  ) async {
    // The server can offer a game before the app knows it; the tile must not
    // crash on the way to saying so.
    await _paint(tester, 'a-game-added-later', 38);
  });

  testWidgets('art survives a tiny size without throwing', (tester) async {
    await _paint(tester, 'cricket', 12);
  });

  testWidgets('accent and opacity are honoured', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameArt(
            slug: 'cricket',
            size: 64,
            accent: Color(0xFF00FF00),
            opacity: 0.4,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(GameArt), findsOneWidget);
  });
}
