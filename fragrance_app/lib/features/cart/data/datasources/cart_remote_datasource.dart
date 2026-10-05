import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import 'cart_endpoint.dart';

abstract interface class CartRemoteDatasource {
  Future<List<ProductModel>> getCartItems(List<String> ids);
}

final class CartRemoteDatasourceImpl implements CartRemoteDatasource {
  final ApiClient _apiClient;

  const CartRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getCartItems(List<String> ids) async {
    final response = await _apiClient.post(
      path: CartEndpoint.getCartItems,
      data: ids,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }
}
