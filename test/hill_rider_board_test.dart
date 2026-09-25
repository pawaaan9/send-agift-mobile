import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/games/domain/hill_rider.dart';
import 'package:send_agift_mobile/features/games/presentation/game_controls.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/hill_rider_board.dart';
import 'package:send_agift_mobile/features/games/presentation/widgets/hill_vehicles.dart';

Future<HillRider> _pumpBoard(WidgetTester tester, {Key? key}) async {
  final game = HillRider(seed: 'cafebabe');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 620,
          child: HillRiderBoard(
            key: key,
            game: game,
            controls: GameControls(active: true, onChanged: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return game;
}

void main() {
  test('there are several vehicles, each its own', () {
    expect(hillVehicles.length, greaterThanOrEqualTo(3));
    expect(
      hillVehicles.map((v) => v.name).toSet(),
      hasLength(hillVehicles.length),
    );
    for (final vehicle in hillVehicles) {
      expect(vehicle.wheelRadius, greaterThan(0));
      expect(vehicle.axle, greaterThan(0));
    }
  });

  testWidgets('the run opens on the vehicle chooser', (tester) async {
    final game = await _pumpBoard(tester);

    expect(find.text('Pick your ride'), findsOneWidget);
    for (final vehicle in hillVehicles) {
      expect(find.text(vehicle.name), findsOneWidget);
    }
    expect(
      game.distance,
      0,
      reason: 'nothing is driven until a vehicle is picked',
    );
  });

  testWidgets('picking a vehicle puts the pedals on the road', (tester) async {
    await _pumpBoard(tester);

    await tester.tap(find.text('Monster truck'));
    await tester.pump();

    expect(find.text('Pick your ride'), findsNothing);
    expect(find.byKey(const ValueKey('hill-gas')), findsOneWidget);
    expect(find.byKey(const ValueKey('hill-brake')), findsOneWidget);
  });

  testWidgets('the vehicle chosen does not change the drive', (tester) async {
    // The hills, the fuel and the scoring are the engine's. Two players on
    // one seed drive the same course whichever vehicle they picked.
    final first = await _pumpBoard(tester, key: const ValueKey('a'));
    await tester.tap(find.text('Dune buggy'));
    await tester.pump();
    final buggy = await _drive(tester, first);

    final second = await _pumpBoard(tester, key: const ValueKey('b'));
    await tester.tap(find.text('Gift van'));
    await tester.pump();
    final van = await _drive(tester, second);

    // Both actually drove: two zeroes would match without proving anything.
    expect(buggy, greaterThan(0), reason: 'the buggy never moved');
    expect(van, buggy);
  });
}

/// Holds the gas for a fixed stretch and reports how far it got.
Future<int> _drive(WidgetTester tester, HillRider game) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey('hill-gas'))),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await gesture.up();
  await tester.pump();
  return game.distance;
}
