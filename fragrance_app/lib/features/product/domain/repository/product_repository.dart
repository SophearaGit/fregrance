import '../../../../core/core.dart';
import '../../data/model/product_model.dart';

abstract interface class ProductRepository {
  Future<ApiPaginationResponse<List<ProductModel>>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
  });

  Future<ProductModel> getOneProductById(String id);

  Future<List<ProductModel>> getManyProductByIds();
}
