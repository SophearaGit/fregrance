import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../domain/repository/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../model/featured_model.dart';

final class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource _remoteDatasource;

  const HomeRepositoryImpl(this._remoteDatasource);

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getFeed({
    String? tab,
    int? page,
    int? limit,
  }) async {
    return _remoteDatasource.getFeed(tab: tab, page: page, limit: limit);
  }

  @override
  Future<ApiResponse<FeaturedModel>> getFeatured() async {
    return _remoteDatasource.getFeatured();
  }
}
