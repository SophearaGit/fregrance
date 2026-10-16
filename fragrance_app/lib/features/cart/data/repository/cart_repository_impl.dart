import '../../../product/data/model/product_enum.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/payway_checkout.dart';
import '../../domain/repository/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

final class CartRepositoryImpl implements CartRepository {
  final CartRemoteDatasource _remoteDatasource;

  const CartRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<CartItem>> getCartItems(List<String> ids) async {
    // Ask for each product once, then keep the order they were added in.
    final uniqueIds = ids.toSet().toList();
    final productModels = await _remoteDatasource.getCartItems(uniqueIds);
    final byId = {for (final model in productModels) model.id: model};

    final items = <CartItem>[];
    for (final id in uniqueIds) {
      final model = byId[id];
      if (model == null) continue; // Deleted in the admin site.

      String? resolvedImageUrl;
      if (model.images.isNotEmpty) {
        final index = model.defaultImageIndex;
        resolvedImageUrl =
            (index != null && index >= 0 && index < model.images.length)
            ? model.images[index]
            : model.images.first;
      }

      items.add(
        CartItem(
          productId: model.id,
          name: model.name,
          price: model.price,
          imageUrl: resolvedImageUrl ?? '',
          quantity: ids.where((item) => item == id).length,
          brand: model.brand,
          size: model.size ?? '',
          discount: model.discount ?? 0,
          stock: model.stock,
          isAvailable:
              model.status == ProductStatus.active && model.stock > 0,
        ),
      );
    }
    return items;
  }

  @override
  Future<String?> placeOrder(List<CartItem> items) =>
      _remoteDatasource.placeOrder(_orderLines(items));

  @override
  Future<PaywayCheckout> startPayway(List<CartItem> items) =>
      _remoteDatasource.startPayway(_orderLines(items));

  @override
  Future<String> checkPayway(String tranId) =>
      _remoteDatasource.checkPayway(tranId);

  List<Map<String, Object>> _orderLines(List<CartItem> items) => [
    for (final item in items)
      {'productId': item.productId, 'quantity': item.quantity},
  ];
}
