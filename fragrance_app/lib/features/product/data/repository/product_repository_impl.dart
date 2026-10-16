import '../../../../core/core.dart';
import '../../domain/repository/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../model/product_model.dart';

final class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource _remoteDatasource;

  const ProductRepositoryImpl(this._remoteDatasource);

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return _remoteDatasource.getProducts(
      page: page,
      limit: limit,
      search: search,
    );
  }

  @override
  Future<ProductModel> getOneProductById(String id) async {
    final response = await _remoteDatasource.getOneById(id);
    return response.data;
  }

  @override
  Future<List<ProductModel>> getManyProductByIds() async {
    final response = await _remoteDatasource.getManyByIds();
    return response.data;
  }
}
