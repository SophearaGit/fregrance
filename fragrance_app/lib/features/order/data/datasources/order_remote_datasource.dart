import '../../../../core/core.dart';
import '../model/order_model.dart';

abstract interface class OrderRemoteDatasource {
  /// GET /order: the customer's orders, newest first.
  Future<List<OrderModel>> getOrders();

  /// POST /order/{id}/received: the customer got the parcel.
  Future<void> markReceived(String orderId);
}

final class OrderRemoteDatasourceImpl implements OrderRemoteDatasource {
  final ApiClient _apiClient;

  const OrderRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await _apiClient.get(path: '/order');
    final data = response.data?['data'];
    return [
      if (data is List)
        for (final item in data) OrderModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> markReceived(String orderId) async {
    await _apiClient.post(path: '/order/$orderId/received');
  }
}
