import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/app/app.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SendAGiftApp()));
    await tester.pumpAndSettle();

    expect(find.text('SendAGift'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
