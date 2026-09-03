import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:send_agift_mobile/features/cart/data/cart_controller.dart';
import 'package:send_agift_mobile/features/cart/data/cart_storage.dart';
import 'package:send_agift_mobile/features/cart/domain/cart_item.dart';
import 'package:send_agift_mobile/features/saved/data/saved_controller.dart';

/// Restoring from storage is asynchronous. A customer can tap "add to cart"
/// inside that window, and their action must not be thrown away when the
/// restore lands.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an item added before the restore lands is kept and merged', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = CartStorage();
    await storage.write(const [CartItem(giftId: 'stored', quantity: 2)]);

    final controller = CartController(storage);
    // Same frame as construction: the restore future has not completed yet.
    controller.add('added');

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final ids = controller.state.map((item) => item.giftId).toSet();
    expect(ids, {'stored', 'added'});

    // The merge is written back, so it survives the next launch too.
    final reread = await storage.read();
    expect(reread.map((item) => item.giftId).toSet(), {'stored', 'added'});
  });

  test('a gift saved before the restore lands is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_gift_ids_v1', ['stored']);

    final controller = SavedGiftsController();
    controller.toggle('added');

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state, {'stored', 'added'});
  });
}
