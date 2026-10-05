import '../../../../core/core.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repository/cart_repository.dart';

final class CartProvider extends AppProvider {
  final CartRepository _repository;

  // ----------- [Constructor] -----------
  CartProvider(this._repository);
  // -------------------------------------

  // =========== [State] ============
  List<String> _productIds = [];
  List<CartItem> _cartItems = [];
  // ================================

  // =========== [Getter] ============
  List<String> get productIds => List.unmodifiable(_productIds);
  List<CartItem> get cartItems => _cartItems;
  int get itemCount => _productIds.length;
  // ================================

  // ----------- [Functions] -----------
  /// Load cart items from local storage
  Future<void> loadCart() async => await execute(() async {
    _productIds = CartPreferences.cart;

    if (_productIds.isEmpty) {
      _cartItems = [];
    } else {
      _cartItems = await _repository.getCartItems(_productIds);
    }

    notifyListeners(); // Refresh
  });

  /// Add a product ID to the cart and persist it
  Future<void> addId(String productId) async => execute(() async {
    if (!productIds.contains(productId)) {
      final updatedIds = List<String>.from(_productIds)..add(productId);
      await CartPreferences.setCartItems(updatedIds);
      _productIds = updatedIds;
      _cartItems = await _repository.getCartItems(_productIds);
      notifyListeners(); // Refresh
    }
  });

  /// Remove a product ID from the cart and persist it
  Future<void> removeId(String productId) async => execute(() async {
    final updatedIds = List<String>.from(_productIds)..remove(productId);
    await CartPreferences.setCartItems(updatedIds);
    _productIds = updatedIds;
    _cartItems = _productIds.isEmpty
        ? []
        : await _repository.getCartItems(_productIds);
    notifyListeners(); // Refresh
  });

  /// Cleat all IDs from cart
  Future<void> clearCart() async => execute(() async {
    await CartPreferences.clear();
    _productIds = [];
    _cartItems = [];
    notifyListeners(); // Refreshs
  });
  // -------------------------------------
}
