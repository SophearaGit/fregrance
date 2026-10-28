import '../../../core/core.dart';
import '../../product/data/model/product_model.dart';

abstract interface class FavoriteRemoteDatasource {
  /// GET /favorite: the saved products, newest first.
  Future<List<ProductModel>> getFavorites();

  /// GET /favorite/ids: just the ids, to colour the hearts.
  Future<Set<String>> getIds();

  /// POST /favorite/{id}/toggle: returns true when it is now saved.
  Future<bool> toggle(String productId);
}

final class FavoriteRemoteDatasourceImpl implements FavoriteRemoteDatasource {
  final ApiClient _apiClient;

  const FavoriteRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getFavorites() async {
    final response = await _apiClient.get(path: '/favorite');
    final data = response.data?['data'];
    return [
      if (data is List)
        for (final item in data)
          ProductModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Set<String>> getIds() async {
    final response = await _apiClient.get(path: '/favorite/ids');
    final data = response.data?['data'];
    return {
      if (data is List)
        for (final id in data) id.toString(),
    };
  }

  @override
  Future<bool> toggle(String productId) async {
    final response = await _apiClient.post(
      path: '/favorite/$productId/toggle',
    );
    final data = response.data?['data'];
    return data is Map<String, dynamic> && data['favorite'] == true;
  }
}
