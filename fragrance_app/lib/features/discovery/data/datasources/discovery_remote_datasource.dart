import '../../../../core/core.dart';
import '../../../product/data/model/fragrance_notes_model.dart';
import '../../../product/data/model/product_model.dart';
import 'discovery_endpoints.dart';

abstract interface class DiscoveryRemoteDatasource {
  Future<ApiResponse<List<String>>> getMoods();

  Future<ApiResponse<FragranceNotesModel>> getNotes();

  Future<ApiResponse<List<String>>> getOccasion();

  Future<ApiResponse<List<String>>> getScentFamilies();

  Future<ApiPaginationResponse<List<ProductModel>>> getFilter({
    String? mood,
    String? note,
    String? occasion,
    String? family,
    String? type,
    int? page,
    int? limit,
  });
}

final class DiscoveryRemoteDatasourceImpl implements DiscoveryRemoteDatasource {
  final ApiClient _apiClient;

  const DiscoveryRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ApiResponse<List<String>>> getMoods() async {
    final response = await _apiClient.get(path: DiscoveryEndpoints.moods);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => List<String>.from(json as List),
    );
  }

  @override
  Future<ApiResponse<FragranceNotesModel>> getNotes() async {
    final response = await _apiClient.get(path: DiscoveryEndpoints.notes);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FragranceNotesModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<String>>> getOccasion() async {
    final response = await _apiClient.get(path: DiscoveryEndpoints.occasions);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => List<String>.from(json as List),
    );
  }

  @override
  Future<ApiResponse<List<String>>> getScentFamilies() async {
    final response = await _apiClient.get(
      path: DiscoveryEndpoints.scentFamilies,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => List<String>.from(json as List),
    );
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
    final response = await _apiClient.get(
      path: DiscoveryEndpoints.filter(
        mood: mood,
        note: note,
        occasion: occasion,
        family: family,
        type: type,
        page: page,
        limit: limit,
      ),
    );

    return ApiPaginationResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
