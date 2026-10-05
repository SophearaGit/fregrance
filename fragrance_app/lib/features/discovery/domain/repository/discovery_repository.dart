import '../../../../core/core.dart';
import '../../../product/data/model/fragrance_notes_model.dart';
import '../../../product/data/model/product_model.dart';

abstract interface class DiscoveryRepository {
  Future<ApiResponse<List<String>>> getMoods();

  Future<ApiResponse<FragranceNotesModel>> getNotes();

  Future<ApiResponse<List<String>>> getOccasions();

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
