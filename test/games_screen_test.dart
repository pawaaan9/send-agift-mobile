import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/domain/game.dart';
import 'package:send_agift_mobile/features/games/presentation/game_definitions.dart';
import 'package:send_agift_mobile/features/games/presentation/game_visuals.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/games_screen.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/game_art.dart';

import 'support/fake_games_repository.dart';

/// Every game the backend seeds (migrations 000027–000032).
const _catalog = [
  '2048',
  'snake',
  'slide-puzzle',
  'basketball',
  'stack-tower',
  'archery',
  'cricket',
  'block-blast',
  'sling-shot',
  'hill-rider',
  'memory-match',
  'whack-a-mole',
  'bubble-shooter',
  'tower-blocks',
  'fruit-slice',
  'doodle-jump',
];

/// The standard fake, plus a game this build of the app cannot run.
class _WithFutureGame extends FakeGamesRepository {
  @override
  Future<List<Game>> listGames() async => [
    ...FakeGamesRepository.games,
    const Game(
      slug: 'future-game',
      name: 'Future Game',
      gameType: 'puzzle',
      version: '1.0.0',
      config: {},
    ),
  ];
}

Future<void> _frames(WidgetTester tester, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  test('every game in the catalog can be opened and has its own look', () {
    for (final slug in _catalog) {
      expect(gameDefinitions, contains(slug), reason: '$slug has no engine');
      expect(
        GameVisual.of(slug).name,
        isNot('Game'),
        reason: '$slug falls back to the generic look',
      );
    }
  });

  testWidgets(
    'a game this build cannot run explains instead of doing nothing',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesRepositoryProvider.overrideWithValue(_WithFutureGame()),
          ],
          child: const MaterialApp(home: GamesScreen()),
        ),
      );
      await _frames(tester);

      await tester.scrollUntilVisible(
        find.text('Future Game'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // scrollUntilVisible stops as soon as the widget is attached, which can
      // leave the last tile of a long list sitting just past the fold.
      await tester.ensureVisible(find.text('Future Game'));
      await _frames(tester, 200);
      await tester.tap(find.text('Future Game'));
      await _frames(tester);

      expect(
        find.text('Future Game needs the latest version of the app.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('game tiles fit their card on a small phone', (tester) async {
    // The tile used to be half again as tall as it was wide, with the artwork
    // watermarked under the tagline. Tightening the card risks the opposite
    // failure, so this pins it: no overflow at the narrowest size we ship to.
    tester.view.physicalSize = const Size(750, 1334); // iPhone SE
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(FakeGamesRepository()),
        ],
        child: const MaterialApp(home: GamesScreen()),
      ),
    );
    await _frames(tester);

    expect(tester.takeException(), isNull);

    // Scroll the whole list so every tile gets laid out, not just the first row.
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull, reason: 'overflow while scrolling');
    }
  });

  testWidgets('a tile shows its name, tagline and artwork', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(FakeGamesRepository()),
        ],
        child: const MaterialApp(home: GamesScreen()),
      ),
    );
    await _frames(tester);

    expect(find.text('2048'), findsWidgets);
    expect(find.text(GameVisual.of('2048').tagline), findsOneWidget);
    // The artwork is the tile's subject now, so it has to actually be there.
    expect(find.byType(GameArt), findsWidgets);
  });
}
