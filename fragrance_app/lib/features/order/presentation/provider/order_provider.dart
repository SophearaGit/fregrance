import 'dart:developer';

import '../../../../core/core.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/model/order_model.dart';

final class OrderProvider extends AppProvider {
  final OrderRemoteDatasource _datasource;

  OrderProvider(this._datasource);

  List<OrderModel> _orders = [];
  bool _loaded = false;

  List<OrderModel> get orders => _orders;

  /// True once the list has been fetched at least once.
  bool get loaded => _loaded;

  Future<void> loadOrders() async => execute(
    () async {
      if (!AuthPreferences.isAuthenticated) {
        _orders = [];
        return;
      }
      _orders = await _datasource.getOrders();
      _loaded = true;
    },
    onError: (Object error) {
      log('loadOrders error: $error');
      setError(
        error is ApiException
            ? error.message
            : 'Could not reach the shop. Is Laragon running?',
      );
    },
  );

  /// Quiet reload (no spinner), e.g. when the admin changes an order status.
  Future<void> refresh() async {
    if (!_loaded || isLoading || !AuthPreferences.isAuthenticated) return;
    _orders = await _datasource.getOrders();
    notifyListeners();
  }

  /// Returns null when it worked, otherwise the reason.
  Future<String?> markReceived(String orderId) async {
    try {
      await _datasource.markReceived(orderId);
      await refresh();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not reach the shop. Is Laragon running?';
    }
  }

  void clear() {
    _orders = [];
    _loaded = false;
    notifyListeners();
  }
}
