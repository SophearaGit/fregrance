import '../entities/cart_item.dart';
import '../entities/payway_checkout.dart';

abstract interface class CartRepository {
  /// [ids] has one entry per unit, so a product listed twice has quantity 2.
  Future<List<CartItem>> getCartItems(List<String> ids);

  /// Pay for [items] from the signed-in customer's wallet.
  /// Returns the new order's id.
  Future<String?> placeOrder(List<CartItem> items);

  /// Start paying for [items] with ABA PayWay.
  Future<PaywayCheckout> startPayway(List<CartItem> items);

  /// 'paid', 'pending' or 'cancelled'.
  Future<String> checkPayway(String tranId);
}
