import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../data/model/brand_model.dart';

abstract interface class BrandRepository {
  Future<ApiResponse<List<BrandModel>>> getBrands();

  Future<ApiPaginationResponse<List<ProductModel>>> getBrandProducts({
    String? name,
    int? page,
    int? limit,
  });
}
