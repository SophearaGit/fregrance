import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../model/brand_model.dart';
import 'brand_endpoints.dart';

abstract interface class BrandRemoteDatasource {
  Future<ApiResponse<List<BrandModel>>> getBrands();

  Future<ApiPaginationResponse<List<ProductModel>>> getBrandProducts({
    String? name,
    int? page,
    int? limit,
  });
}

final class BrandRemoteDatasourceImpl implements BrandRemoteDatasource {
  final ApiClient _apiClient;

  const BrandRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ApiResponse<List<BrandModel>>> getBrands() async {
    final response = await _apiClient.get(path: BrandEndpoints.brand);

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getBrandProducts({
    String? name,
    int? page = 1,
    int? limit = 10,
  }) async {
    final endpoint = BrandEndpoints.brandProducts(
      name: name,
      page: page.toString(),
      limit: limit.toString(),
    );

    final response = await _apiClient.getDynamic(path: endpoint);

    final responseMap = response.data is Map<String, dynamic>
        ? Map<String, dynamic>.from(response.data as Map<String, dynamic>)
        : <String, dynamic>{
            'message': '',
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 10,
              'total': 0,
              'hasNext': false,
              'hasPrevious': false,
            },
          };

    return ApiPaginationResponse.fromJson(responseMap, (jsonData) {
      final list = jsonData is List ? jsonData : [];
      return list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }
}
