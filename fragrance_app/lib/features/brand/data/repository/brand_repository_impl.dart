import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../domain/repository/brand_repository.dart';
import '../datasources/brand_remote_datasource.dart';
import '../model/brand_model.dart';

final class BrandRepositoryImpl implements BrandRepository {
  final BrandRemoteDatasource _remoteDatasource;

  const BrandRepositoryImpl(this._remoteDatasource);

  @override
  Future<ApiResponse<List<BrandModel>>> getBrands() async {
    return _remoteDatasource.getBrands();
  }

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getBrandProducts({
    String? name,
    int? page,
    int? limit,
  }) async {
    return _remoteDatasource.getBrandProducts(
      name: name,
      page: page,
      limit: limit,
    );
  }
}
