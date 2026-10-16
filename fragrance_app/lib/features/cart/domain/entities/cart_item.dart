/// One product line in the cart.
final class CartItem {
  final String productId;
  final String name;
  final String brand;
  final String size;
  final double price; // Original price
  final int quantity;
  final double? discount; // 0-100 (%)
  final String? imageUrl;
  final int stock;

  /// False when the admin hid the product or it is out of stock.
  final bool isAvailable;

  const CartItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.size,
    required this.price,
    required this.quantity,
    required this.stock,
    required this.isAvailable,
    this.discount = 0,
    this.imageUrl = '',
  });

  bool get hasDiscount => (discount ?? 0) > 0;

  /// Price of one, after the discount, rounded to cents like the backend does.
  double get unitPrice {
    final value = hasDiscount ? price * (1 - discount! / 100) : price;
    return (value * 100).round() / 100;
  }

  double get lineTotal => unitPrice * quantity;

  bool get canIncrease => isAvailable && quantity < stock;

  /// More in the cart than the shop has left.
  bool get exceedsStock => quantity > stock;

  bool get canOrder => isAvailable && !exceedsStock;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    name: name,
    brand: brand,
    size: size,
    price: price,
    quantity: quantity ?? this.quantity,
    stock: stock,
    isAvailable: isAvailable,
    discount: discount,
    imageUrl: imageUrl,
  );
}
