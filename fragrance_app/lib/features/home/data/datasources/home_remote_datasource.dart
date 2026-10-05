import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../model/featured_model.dart';
import 'home_endpoint.dart';

abstract interface class HomeRemoteDatasource {
  Future<ApiPaginationResponse<List<ProductModel>>> getFeed({
    String? tab,
    int? page,
    int? limit,
  });
  Future<ApiResponse<FeaturedModel>> getFeatured();
}

final class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  final ApiClient _apiClient;

  const HomeRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getFeed({
    String? tab,
    int? page,
    int? limit,
  }) async {
    final response = await _apiClient.get(
      path: HomeEndpoint.feed(tab: tab, page: page, limit: limit),
    );

    return ApiPaginationResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ApiResponse<FeaturedModel>> getFeatured() async {
    final response = await _apiClient.get(path: HomeEndpoint.featured);

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FeaturedModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
