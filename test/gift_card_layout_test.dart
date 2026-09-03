import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/core/theme/app_theme.dart';
import 'package:send_agift_mobile/features/products/domain/gift.dart';
import 'package:send_agift_mobile/features/products/presentation/widgets/gift_grid.dart';

/// The gift card overflowed on Android because the grid guessed a fixed aspect
/// ratio while text height varies by platform and user font scale. These cases
/// pin the sizing: a card must never overflow, however tall its text renders.
void main() {
  final gifts = [
    const Gift(
      id: '1',
      name: 'Perfume',
      priceAmount: 2500,
      currency: 'AUD',
      image: 'https://example.com/a.jpg',
      shopName: 'PD Gifts',
    ),
    const Gift(
      id: '2',
      name: 'An extremely long gift name that wraps well past two lines',
      priceAmount: 12999,
      compareAtAmount: 19999,
      currency: 'AUD',
      image: 'https://example.com/b.jpg',
      shopName: 'A shop with a very long trading name indeed',
    ),
  ];

  Future<void> pumpGrid(
    WidgetTester tester, {
    required Size surface,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(child: GiftGrid(gifts: gifts)),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('cards do not overflow on a narrow phone', (tester) async {
    await pumpGrid(tester, surface: const Size(360, 640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards do not overflow on a large phone', (tester) async {
    await pumpGrid(tester, surface: const Size(430, 932));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards do not overflow at a large system font scale',
      (tester) async {
    await pumpGrid(tester, surface: const Size(360, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
