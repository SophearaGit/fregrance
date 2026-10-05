import '../../../../core/core.dart';
import '../../../product/data/model/fragrance_notes_model.dart';
import '../../../product/data/model/product_model.dart';
import '../../domain/repository/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

final class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDatasource _remoteDatasource;

  const DiscoveryRepositoryImpl(this._remoteDatasource);

  @override
  Future<ApiResponse<List<String>>> getMoods() async {
    return _remoteDatasource.getMoods();
  }

  @override
  Future<ApiResponse<FragranceNotesModel>> getNotes() async {
    return _remoteDatasource.getNotes();
  }

  @override
  Future<ApiResponse<List<String>>> getOccasions() async {
    return _remoteDatasource.getOccasion();
  }

  @override
  Future<ApiResponse<List<String>>> getScentFamilies() async {
    return _remoteDatasource.getScentFamilies();
  }

  @override
  Future<ApiPaginationResponse<List<ProductModel>>> getFilter({
    String? mood,
    String? note,
    String? occasion,
    String? family,
    String? type,
    int? page,
    int? limit,
  }) async {
    return _remoteDatasource.getFilter();
  }
}
