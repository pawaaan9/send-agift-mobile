/// Occasion categories shown on the home shelf and the explore filters.
/// Ids match the web frontend's `giftCategories` so deep links stay compatible.
class GiftCategory {
  const GiftCategory({
    required this.id,
    required this.name,
    required this.image,
  });

  final String id;
  final String name;
  final String image;

  static const List<GiftCategory> all = [
    GiftCategory(
      id: 'birthday',
      name: 'Birthday',
      image:
          'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?auto=format&fit=crop&w=400&q=80',
    ),
    GiftCategory(
      id: 'flowers',
      name: 'Flowers',
      image:
          'https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=400&q=80',
    ),
    GiftCategory(
      id: 'hampers',
      name: 'Hampers',
      image:
          'https://images.unsplash.com/photo-1607345366928-199ea26cfe3e?auto=format&fit=crop&w=400&q=80',
    ),
    GiftCategory(
      id: 'wellness',
      name: 'Wellness',
      image:
          'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=400&q=80',
    ),
    GiftCategory(
      id: 'tech',
      name: 'Tech Gifts',
      image:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
    ),
    GiftCategory(
      id: 'keepsakes',
      name: 'Keepsakes',
      image:
          'https://images.unsplash.com/photo-1512909006721-3d6018887383?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static String nameFor(String id) {
    for (final category in all) {
      if (category.id == id) return category.name;
    }
    return id.isEmpty ? 'Gift' : id;
  }
}
