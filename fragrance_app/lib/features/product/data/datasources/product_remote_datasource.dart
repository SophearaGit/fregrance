import '../../../../core/core.dart';
import '../model/product_model.dart';
import 'product_endpoint.dart';

abstract interface class ProductRemoteDatasource {
  Future<ApiPaginationResponse<List<ProductModel>>> getProducts({
    int page = 1,
    int limit = 20,
  });

  Future<ApiResponse<ProductModel>> getOneById(String id);
  Future<ApiResponse<List<ProductModel>>> getManyByIds();
}

final class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  final ApiClient _apiClient;

  ProductRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getProducts({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      path: ProductEndpoint.products,
      queryParamters: {'page': page, 'limit': limit},
    );

    // log(response.data.toString());

    return ApiPaginationResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ApiResponse<ProductModel>> getOneById(String id) async {
    final response = await _apiClient.get(path: ProductEndpoint.getOneById(id));

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ProductModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<ProductModel>>> getManyByIds() async {
    final response = await _apiClient.get(path: ProductEndpoint.getManyByIds);

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
