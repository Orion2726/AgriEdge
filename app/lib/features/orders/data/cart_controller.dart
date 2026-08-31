import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral cart state — intentionally not persisted to Drift. If the app
/// is killed mid-shop the cart resets, same as most shopping apps; only a
/// *placed* order needs offline durability, which OrdersRepository handles.
class CartController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void setQuantity(String productId, int quantity) {
    final next = Map<String, int>.from(state);
    if (quantity <= 0) {
      next.remove(productId);
    } else {
      next[productId] = quantity;
    }
    state = next;
  }

  void increment(String productId) {
    setQuantity(productId, (state[productId] ?? 0) + 1);
  }

  void decrement(String productId) {
    setQuantity(productId, (state[productId] ?? 0) - 1);
  }

  void clear() => state = {};
}

final cartControllerProvider = NotifierProvider<CartController, Map<String, int>>(CartController.new);
