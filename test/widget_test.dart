import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/app/app.dart';

void main() {
  testWidgets('App opens on the storefront without asking anyone to sign in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SendAGiftApp()));
    await tester.pump();

    // The hero, not a login wall, is the first thing a new user sees.
    expect(find.text('Discover the best gifts for every moment.'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    // The nav bar is icons-only, so the tabs are found by the semantics
    // labels that announce them to screen readers.
    for (final tab in ['Home', 'Explore', 'Saved', 'Cart', 'Account']) {
      expect(find.bySemanticsLabel(tab), findsOneWidget);
    }
  });
}
