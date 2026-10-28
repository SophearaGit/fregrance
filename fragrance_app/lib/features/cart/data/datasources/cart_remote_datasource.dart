import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../domain/entities/payway_checkout.dart';
import 'cart_endpoint.dart';

abstract interface class CartRemoteDatasource {
  Future<List<ProductModel>> getCartItems(List<String> ids);

  /// POST /order with [{productId, quantity}] paid from the wallet.
  /// Returns the new order's id.
  Future<String?> placeOrder(
    List<Map<String, Object>> items, {
    String? deliveryDetail,
  });

  /// POST /order/payway: save a pending order and get the payment page.
  Future<PaywayCheckout> startPayway(
    List<Map<String, Object>> items, {
    String? deliveryDetail,
  });

  /// POST /order/payway/check: 'paid', 'pending' or 'cancelled'.
  Future<String> checkPayway(String tranId);
}

final class CartRemoteDatasourceImpl implements CartRemoteDatasource {
  final ApiClient _apiClient;

  const CartRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getCartItems(List<String> ids) async {
    final response = await _apiClient.post(
      path: CartEndpoint.getCartItems,
      data: ids,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  @override
  Future<String?> placeOrder(
    List<Map<String, Object>> items, {
    String? deliveryDetail,
  }) async {
    final response = await _apiClient.post(
      path: CartEndpoint.order,
      data: {
        'items': items,
        'paymentMethod': 'wallet',
        if (deliveryDetail != null) 'deliveryDetail': deliveryDetail,
      },
    );
    final data = response.data?['data'];
    final id = data is Map<String, dynamic> ? data['id'] : null;
    return id is String ? id : null;
  }

  @override
  Future<PaywayCheckout> startPayway(
    List<Map<String, Object>> items, {
    String? deliveryDetail,
  }) async {
    final response = await _apiClient.post(
      path: CartEndpoint.payway,
      data: {
        'items': items,
        if (deliveryDetail != null) 'deliveryDetail': deliveryDetail,
      },
    );
    return PaywayCheckout.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<String> checkPayway(String tranId) async {
    final response = await _apiClient.post(
      path: CartEndpoint.paywayCheck,
      data: {'tranId': tranId},
    );
    final data = response.data?['data'];
    final status = data is Map<String, dynamic> ? data['status'] : null;
    return status is String ? status : 'pending';
  }
}
