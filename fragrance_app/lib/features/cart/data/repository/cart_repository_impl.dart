import '../../domain/entities/cart_item.dart';
import '../../domain/repository/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

final class CartRepositoryImpl implements CartRepository {
  final CartRemoteDatasource _remoteDatasource;

  const CartRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<CartItem>> getCartItems(List<String> ids) async {
    final productModels = await _remoteDatasource.getCartItems(ids);

    return productModels.map((model) {
      // Resolve image URL
      String? resolvedImageUrl;
      if (model.images.isNotEmpty) {
        final index = model.defaultImageIndex;
        resolvedImageUrl =
            (index != null && index >= 0 && index < model.images.length)
            ? model.images[index]
            : model.images.first;
      }

      // Calculate quantity based on how many times this ID appears in the local list
      final itemQuantity = ids.where((id) => id == model.id).length;

      return CartItem(
        name: model.name,
        price: model.price,
        imageUrl: resolvedImageUrl ?? '',
        quantity: itemQuantity > 0 ? itemQuantity : 1,
        brand: model.brand,
        size: model.size ?? '',
        discount: model.discount ?? 0,
      );
    }).toList();
  }
}
