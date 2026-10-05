import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../data/model/featured_model.dart';

abstract interface class HomeRepository {
  Future<ApiPaginationResponse<List<ProductModel>>> getFeed({
    String? tab,
    int? page,
    int? limit,
  });
  Future<ApiResponse<FeaturedModel>> getFeatured();
}
