final class CartItem {
  final String name;
  final String brand;
  final String size;
  final double price;
  final int quantity;
  final double? discount;
  final String? imageUrl;

  const CartItem({
    required this.name,
    required this.brand,
    required this.size,
    required this.price,
    required this.quantity,
    this.discount = 0,
    this.imageUrl = '',
  });
}
