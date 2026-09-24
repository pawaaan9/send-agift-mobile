import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/presentation/game_definitions.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/game_play_screen.dart'
    show GamePlayScreen, gamePlayAreaKey;

import 'support/fake_games_repository.dart';

/// The games that draw a scene rather than a grid of pieces. A grid is square
/// by nature and cannot fill a tall screen; a scene has no excuse.
const _sceneGames = [
  'basketball',
  'cricket',
  'archery',
  'sling-shot',
  'hill-rider',
  'doodle-jump',
  'stack-tower',
];

Future<Rect> _playArea(WidgetTester tester, String slug) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(FakeGamesRepository()),
      ],
      child: MaterialApp(
        home: GamePlayScreen(definition: gameDefinitions[slug]!),
      ),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return tester.getRect(find.byKey(gamePlayAreaKey));
}

void main() {
  for (final slug in _sceneGames) {
    testWidgets('$slug fills the screen it is given', (tester) async {
      final area = await _playArea(tester, slug);

      // The biggest thing painted below the panels is the scene.
      var scene = Rect.zero;
      for (final element in find.byType(CustomPaint).evaluate()) {
        final box = element.renderObject as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.top < area.top) continue; // the backdrop behind the panels
        if (rect.width * rect.height > scene.width * scene.height) {
          scene = rect;
        }
      }

      // Controls and readouts belong over the scene, not on a strip beneath
      // it: a row of its own used to cost the scene an eighth of the screen.
      expect(
        scene.width,
        area.width,
        reason: '$slug leaves ${(area.width - scene.width).round()}px of width',
      );
      expect(
        scene.height,
        area.height,
        reason:
            '$slug leaves ${(area.height - scene.height).round()}px of height',
      );

      // And the scene is the whole screen: the panels float on it, so the
      // court carries on behind the score rather than stopping at a seam
      // where a different backdrop takes over.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(area.top, 0, reason: '$slug starts below the top of the screen');
      expect(
        area.height,
        screen.height,
        reason: '$slug leaves '
            '${(screen.height - area.height).round()}px of screen unpainted',
      );
    });
  }

  testWidgets('the game reaches the edges of the screen', (tester) async {
    final area = await _playArea(tester, 'cricket');
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    // Inset in a padded card the game read as a widget on a page. Only the
    // panels above and the hint below are allowed to take room.
    expect(area.left, 0);
    expect(area.top, 0);
    expect(area.width, screen.width);
    expect(area.height, screen.height);
  });
}
