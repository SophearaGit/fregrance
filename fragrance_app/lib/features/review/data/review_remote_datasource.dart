import '../../../core/core.dart';
import '../../product/data/model/product_model.dart';
import 'review_model.dart';

abstract interface class ReviewRemoteDatasource {
  /// GET /product/{id}/reviews
  Future<ReviewSummary> getForProduct(
    String productId, {
    int page = 1,
    int limit = 5,
  });

  /// POST /product/{id}/reviews: write or replace the customer's review.
  Future<ReviewModel> save(
    String productId, {
    required int rating,
    required String comment,
  });

  /// POST /review/{id}/delete
  Future<void> delete(String reviewId);

  /// GET /review/mine: every perfume bought, with its review if any.
  Future<List<PurchasedReview>> mine();
}

final class ReviewRemoteDatasourceImpl implements ReviewRemoteDatasource {
  final ApiClient _apiClient;

  const ReviewRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ReviewSummary> getForProduct(
    String productId, {
    int page = 1,
    int limit = 5,
  }) async {
    final response = await _apiClient.get(
      path: '/product/$productId/reviews',
      queryParamters: {'page': page, 'limit': limit},
    );
    return ReviewSummary.fromBody(response.data ?? const {});
  }

  @override
  Future<ReviewModel> save(
    String productId, {
    required int rating,
    required String comment,
  }) async {
    final response = await _apiClient.post(
      path: '/product/$productId/reviews',
      data: {'rating': rating, 'comment': comment},
    );
    return ReviewModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> delete(String reviewId) async {
    await _apiClient.post(path: '/review/$reviewId/delete');
  }

  @override
  Future<List<PurchasedReview>> mine() async {
    final response = await _apiClient.get(path: '/review/mine');
    final data = response.data?['data'];
    return [
      if (data is List)
        for (final item in data.cast<Map<String, dynamic>>())
          (
            product: ProductModel.fromJson(
              item['product'] as Map<String, dynamic>,
            ),
            review: item['review'] is Map<String, dynamic>
                ? ReviewModel.fromJson(item['review'] as Map<String, dynamic>)
                : null,
          ),
    ];
  }
}
