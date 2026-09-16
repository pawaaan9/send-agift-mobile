import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_agift_mobile/features/reviews/domain/product_review.dart';
import 'package:send_agift_mobile/features/reviews/presentation/widgets/star_rating.dart';

void main() {
  group('ProductReview.fromJson', () {
    test('reads a full review with media and author', () {
      final review = ProductReview.fromJson({
        'id': 'r1',
        'product_id': 'p1',
        'order_item_id': 'oi1',
        'rating': 5,
        'product_quality_rating': 5,
        'shipping_rating': 4,
        'seller_service_rating': 5,
        'title': 'Great gift',
        'body': 'Arrived on time.',
        'is_anonymous': false,
        'helpful_count': 3,
        'created_at': '2026-09-15T07:30:00Z',
        'media': [
          {
            'media_asset_id': 'm1',
            'position': 0,
            'asset_type': 'image',
            'object_path': 'public/reviews/photos/a.jpg',
            'mime_type': 'image/jpeg',
            'cdn_url': 'https://cdn/a.jpg',
          },
        ],
        'customer': {'display_name': 'Alex'},
        'voted_helpful': true,
      });

      expect(review.rating, 5);
      expect(review.shippingRating, 4);
      expect(review.authorName, 'Alex');
      expect(review.hasVoted, isTrue);
      expect(review.media.single.isVideo, isFalse);
    });

    test('an anonymous review never exposes the display name', () {
      final review = ProductReview.fromJson({
        'is_anonymous': true,
        'customer': {'display_name': 'Alex'},
      });
      expect(review.authorName, 'Anonymous');
    });

    test('a missing vote is not a vote', () {
      final review = ProductReview.fromJson({'id': 'r1'});
      expect(review.votedHelpful, isNull);
      expect(review.hasVoted, isFalse);
    });
  });

  test('ReviewSummary turns the string-keyed breakdown into ints', () {
    final summary = ReviewSummary.fromJson({
      'review_count': 3,
      'avg_rating': 4.5,
      'rating_breakdown': {'5': 2, '4': 1, '3': 0},
    });
    expect(summary.reviewCount, 3);
    expect(summary.avgRating, 4.5);
    expect(summary.breakdown[5], 2);
    expect(summary.breakdown[4], 1);
  });

  test('an untouched sub-score is sent as the overall, never as 0', () {
    // The API rejects anything outside 1–5, so a sub-score the customer never
    // touched has to travel as the overall rating rather than as a zero.
    final json = const ReviewDraft(
      rating: 4,
      qualityRating: 0,
      shippingRating: 2,
      serviceRating: 0,
      isAnonymous: false,
    ).toJson();

    expect(json['rating'], 4);
    expect(json['product_quality_rating'], 4);
    expect(json['seller_service_rating'], 4);
    // An explicit low score is kept exactly as given.
    expect(json['shipping_rating'], 2);
  });

  testWidgets('tapping a star reports that score', (tester) async {
    var picked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StarPicker(
              value: 0,
              label: 'Overall rating',
              starSize: 40,
              onChanged: (value) => picked = value,
            ),
          ),
        ),
      ),
    );

    // Each star occupies starSize + 14% gap; tapping inside the third slot
    // must read as three stars.
    final picker = tester.getTopLeft(find.byType(StarPicker));
    await tester.tapAt(Offset(picker.dx + 40 * 1.14 * 2 + 10, picker.dy + 20));
    await tester.pump();

    expect(picked, 3);
  });

  testWidgets('the picker shows a word for the current score', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarPicker(
            value: 5,
            label: 'Overall rating',
            showWord: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text(ratingWord(5)), findsOneWidget);
  });

  testWidgets('StarMeter fills partially for a fractional score', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StarMeter(value: 4.3, size: 16))),
      ),
    );
    // Two rows of five: the outlines and the clipped gold overlay.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(10));
    expect(
      tester.widget<Semantics>(
        find.ancestor(
          of: find.byType(Row).first,
          matching: find.byType(Semantics),
        ).first,
      ).properties.label,
      '4.3 out of 5 stars',
    );
  });
}
