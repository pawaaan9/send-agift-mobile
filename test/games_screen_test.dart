import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/data/games_providers.dart';
import 'package:send_agift_mobile/features/games/domain/game.dart';
import 'package:send_agift_mobile/features/games/presentation/game_definitions.dart';
import 'package:send_agift_mobile/features/games/presentation/game_visuals.dart';
import 'package:send_agift_mobile/features/games/presentation/screens/games_screen.dart';

import 'support/fake_games_repository.dart';

/// Every game the backend seeds (migrations 000027–000031).
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
      await tester.tap(find.text('Future Game'));
      await _frames(tester);

      expect(
        find.text('Future Game needs the latest version of the app.'),
        findsOneWidget,
      );
    },
  );
}
