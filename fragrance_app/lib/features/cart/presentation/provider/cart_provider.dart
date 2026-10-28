import '../../../../core/core.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/payway_checkout.dart';
import '../../domain/repository/cart_repository.dart';

/// What happened when the customer pressed Checkout.
typedef CheckoutResult = ({
  bool success,
  String message,
  bool needsSignIn,
  String? orderId,
});

/// Result of starting an ABA PayWay payment.
typedef PaywayStart = ({
  PaywayCheckout? checkout,
  String message,
  bool needsSignIn,
});

final class CartProvider extends AppProvider {
  final CartRepository _repository;

  // ----------- [Constructor] -----------
  CartProvider(this._repository);
  // -------------------------------------

  // =========== [State] ============
  /// Saved on the phone, one entry per unit: ["7", "7", "12"] = two of 7, one of 12.
  List<String> _productIds = [];
  List<CartItem> _cartItems = [];
  bool _isCheckingOut = false;
  // ================================

  // =========== [Getter] ============
  List<String> get productIds => List.unmodifiable(_productIds);
  List<CartItem> get cartItems => _cartItems;

  /// Number of units, shown on the cart badge.
  int get itemCount => _productIds.length;
  bool get isCheckingOut => _isCheckingOut;

  double get subtotal =>
      _cartItems.fold<double>(0, (sum, item) => sum + item.lineTotal);

  /// True when an item is hidden, sold out, or has more than the stock left.
  bool get hasProblems => _cartItems.any((item) => !item.canOrder);

  int quantityOf(String productId) =>
      _productIds.where((id) => id == productId).length;
  // ================================

  // ----------- [Functions] -----------
  /// Load the cart saved on the phone and get the latest product details.
  Future<void> loadCart() async => await execute(() async {
    _productIds = List<String>.from(CartPreferences.cart);
    await _fetch(_productIds);
    notifyListeners(); // Refresh
  });

  /// Add one more of a product (from a product card or the detail page).
  /// Returns false when the shop has no more of it.
  Future<bool> addId(String productId, {int? stock}) async {
    final inCart = quantityOf(productId);
    final known = _cartItems.where((item) => item.productId == productId);
    final limit = stock ?? (known.isEmpty ? null : known.first.stock);
    if (limit != null && inCart >= limit) return false;

    final updatedIds = [..._productIds, productId];
    _productIds = updatedIds;
    notifyListeners(); // Badge updates straight away
    await CartPreferences.setCartItems(updatedIds);

    await execute(() async {
      await _fetch(updatedIds);
      notifyListeners();
    });
    return true;
  }

  Future<void> increase(String productId) async {
    final item = _itemOf(productId);
    if (item == null || !item.canIncrease) return;
    await _setQuantity(productId, item.quantity + 1);
  }

  Future<void> decrease(String productId) async {
    final item = _itemOf(productId);
    if (item == null || item.quantity <= 1) return;
    await _setQuantity(productId, item.quantity - 1);
  }

  /// Take a product out of the cart completely.
  Future<void> removeId(String productId) => _setQuantity(productId, 0);

  /// Reload the cart's products quietly (new photo, price or stock).
  /// Called by LiveUpdates.
  Future<void> refresh() async {
    if (isLoading || _isCheckingOut || _productIds.isEmpty) return;
    final ids = List<String>.from(_productIds);
    final items = await _repository.getCartItems(ids);
    if (isLoading || ids.join(',') != _productIds.join(',')) return;
    _cartItems = items;
    notifyListeners();
  }

  /// Clear all IDs from cart
  Future<void> clearCart() async => execute(() async {
    await CartPreferences.clear();
    _productIds = [];
    _cartItems = [];
    notifyListeners(); // Refresh
  });

  /// Pay for everything in the cart from the customer's wallet.
  Future<CheckoutResult> checkout({String? deliveryDetail}) async {
    if (_cartItems.isEmpty || _isCheckingOut) {
      return (
        success: false,
        message: 'Your cart is empty.',
        needsSignIn: false,
        orderId: null,
      );
    }
    if (!AuthPreferences.isAuthenticated) {
      return (
        success: false,
        message: 'Please sign in to check out.',
        needsSignIn: true,
        orderId: null,
      );
    }

    _isCheckingOut = true;
    notifyListeners();
    try {
      final orderId = await _repository.placeOrder(
        _cartItems,
        deliveryDetail: deliveryDetail,
      );
      await CartPreferences.clear();
      _productIds = [];
      _cartItems = [];
      return (
        success: true,
        message: 'Order placed.',
        needsSignIn: false,
        orderId: orderId,
      );
    } on ApiException catch (error) {
      // Stock or prices may have changed: show the latest in the cart.
      await _fetchQuietly();
      return (
        success: false,
        message: error.message,
        needsSignIn: error.status == 401,
        orderId: null,
      );
    } catch (_) {
      return (
        success: false,
        message: 'Could not reach the shop. Is Laragon running?',
        needsSignIn: false,
        orderId: null,
      );
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  /// ABA PayWay step 1: save a pending order and get its payment page.
  Future<PaywayStart> startPayway({String? deliveryDetail}) async {
    if (_cartItems.isEmpty || _isCheckingOut) {
      return (checkout: null, message: 'Your cart is empty.', needsSignIn: false);
    }
    if (!AuthPreferences.isAuthenticated) {
      return (
        checkout: null,
        message: 'Please sign in to check out.',
        needsSignIn: true,
      );
    }
    _isCheckingOut = true;
    notifyListeners();
    try {
      final checkout = await _repository.startPayway(
        _cartItems,
        deliveryDetail: deliveryDetail,
      );
      return (checkout: checkout, message: '', needsSignIn: false);
    } on ApiException catch (error) {
      await _fetchQuietly();
      return (
        checkout: null,
        message: error.message,
        needsSignIn: error.status == 401,
      );
    } catch (_) {
      return (
        checkout: null,
        message: 'Could not reach the shop. Is Laragon running?',
        needsSignIn: false,
      );
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  /// Has [tranId] been paid yet? Used every few seconds while the PayWay page
  /// is open, so the app can move on as soon as the money arrives.
  Future<bool> isPaywayPaid(String tranId) async {
    try {
      return await _repository.checkPayway(tranId) == 'paid';
    } catch (_) {
      return false;
    }
  }

  /// ABA PayWay step 2: after the payment page closes, ask whether it was
  /// paid. Returns 'paid' (cart emptied), 'pending', 'cancelled' or 'error'.
  Future<({String status, String message})> confirmPayway(String tranId) async {
    _isCheckingOut = true;
    notifyListeners();
    try {
      final status = await _repository.checkPayway(tranId);
      if (status == 'paid') {
        await CartPreferences.clear();
        _productIds = [];
        _cartItems = [];
        return (status: status, message: 'Payment received. Thank you!');
      }
      return (
        status: status,
        message: status == 'cancelled'
            ? 'The payment was cancelled.'
            : 'The payment is not finished yet.',
      );
    } on ApiException catch (error) {
      return (status: 'error', message: error.message);
    } catch (_) {
      return (
        status: 'error',
        message: 'Could not reach the shop. Is Laragon running?',
      );
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }
  // -------------------------------------

  CartItem? _itemOf(String productId) {
    for (final item in _cartItems) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  /// Change one product's quantity on screen at once, then save it.
  Future<void> _setQuantity(String productId, int quantity) async {
    final position = _productIds.indexOf(productId);
    final ids = _productIds.where((id) => id != productId).toList();
    if (quantity > 0) {
      // Every id before [position] is another product, so it is still valid.
      final at = position < 0 ? ids.length : position;
      ids.insertAll(at, List.filled(quantity, productId));
    }
    _productIds = ids;
    _cartItems = [
      for (final item in _cartItems)
        if (item.productId != productId)
          item
        else if (quantity > 0)
          item.copyWith(quantity: quantity),
    ];
    notifyListeners();
    await CartPreferences.setCartItems(ids);
  }

  Future<void> _fetch(List<String> ids) async {
    if (ids.isEmpty) {
      _cartItems = [];
      return;
    }
    final items = await _repository.getCartItems(ids);
    if (ids.join(',') != _productIds.join(',')) return; // Changed meanwhile.

    // Forget products that were deleted in the admin site.
    final known = items.map((item) => item.productId).toSet();
    final kept = ids.where(known.contains).toList();
    if (kept.length != ids.length) {
      _productIds = kept;
      await CartPreferences.setCartItems(kept);
    }
    _cartItems = items;
  }

  Future<void> _fetchQuietly() async {
    try {
      await _fetch(List<String>.from(_productIds));
    } catch (_) {
      // Keep what is on screen.
    }
  }
}
