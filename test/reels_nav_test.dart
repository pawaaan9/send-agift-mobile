import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_agift_mobile/core/widgets/app_bottom_nav.dart';
import 'package:send_agift_mobile/features/products/data/catalog_providers.dart';
import 'package:send_agift_mobile/features/products/data/sample_gifts.dart';
import 'package:send_agift_mobile/app/app.dart';
import 'package:send_agift_mobile/features/reels/presentation/screens/reels_screen.dart';

const _navItems = [
  AppBottomNavItem(icon: Icons.home_rounded, label: 'Home'),
  AppBottomNavItem(icon: Icons.search_rounded, label: 'Explore'),
  AppBottomNavItem(
    icon: Icons.movie_filter_rounded,
    label: 'Reels',
    orb: true,
  ),
  AppBottomNavItem(icon: Icons.favorite_rounded, label: 'Saved'),
  AppBottomNavItem(icon: Icons.person_rounded, label: 'Account'),
];

Widget _navHarness({required int currentIndex, required ValueChanged<int> onChanged}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onChanged: onChanged,
        items: _navItems,
      ),
    ),
  );
}

void main() {
  testWidgets('the centre orb renders and reports its own taps',
      (tester) async {
    var tapped = -1;

    await tester.pumpWidget(
      _navHarness(currentIndex: 0, onChanged: (i) => tapped = i),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.movie_filter_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.movie_filter_rounded));
    expect(tapped, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('five tabs fit a narrow phone', (tester) async {
    // The row of tabs is measured inside the bar's padding; get that wrong and
    // the fifth slot overflows.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_navHarness(currentIndex: 2, onChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the orb stays centred whichever tab is selected',
      (tester) async {
    late Rect atHome;
    late Rect atSaved;

    for (final index in [0, 3]) {
      await tester.pumpWidget(_navHarness(currentIndex: index, onChanged: (_) {}));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byIcon(Icons.movie_filter_rounded));
      if (index == 0) {
        atHome = rect;
      } else {
        atSaved = rect;
      }
    }

    // The orb is the bar's anchor: an expanding label on either side must not
    // push it off centre, or a thumb aimed at it lands on a neighbour.
    expect(atSaved.center.dx, closeTo(atHome.center.dx, 0.5));
    expect(atHome.center.dx, closeTo(400, 1));
  });

  testWidgets('the bar draws no wording, but still names its tabs',
      (tester) async {
    await tester.pumpWidget(_navHarness(currentIndex: 3, onChanged: (_) {}));
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Explore', 'Reels', 'Saved', 'Account']) {
      expect(find.text(label), findsNothing);
    }

    // Gone from the surface, still there for screen readers.
    expect(
      tester.getSemantics(find.byIcon(Icons.favorite_rounded)).label,
      'Saved',
    );
  });

  testWidgets('reels feed opens on the first gift', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => sampleGifts),
        ],
        child: const MaterialApp(home: ReelsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(sampleGifts.first.name), findsOneWidget);
    expect(find.text('View gift'), findsOneWidget);
    expect(find.text('Reels'), findsOneWidget);
  });

  testWidgets('each tab opens its own page, reels included', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith((ref) async => sampleGifts)],
        child: const SendAGiftApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // The app opens on the storefront, not on a tab further along the bar.
    expect(find.text('Discover the best gifts for every moment.'), findsOneWidget);

    // Scoped to the bar: the same glyphs (search, heart) also appear inside
    // the pages themselves.
    Future<void> tapTab(IconData icon) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byIcon(icon),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await tapTab(Icons.search_rounded);
    // Explore shows the heading and the "all" filter chip, hence widgets.
    expect(find.text('All gifts'), findsWidgets);

    await tapTab(Icons.movie_filter_rounded);
    expect(find.text('Reels'), findsOneWidget);

    await tapTab(Icons.favorite_rounded);
    expect(find.text('Saved gifts'), findsOneWidget);

    // Account is left out: it reads config through dotenv, which isn't
    // loaded in tests.
  });
}
