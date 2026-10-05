import '../entities/cart_item.dart';

abstract interface class CartRepository {
  Future<List<CartItem>> getCartItems(List<String> ids);
}
