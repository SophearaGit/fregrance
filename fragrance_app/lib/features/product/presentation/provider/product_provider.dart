import 'dart:developer';

import '../../../../core/live/live_updates.dart';
import '../../../../core/providers/app_provider.dart';
import '../../data/model/product_model.dart';
import '../../domain/repository/product_repository.dart';

final class ProductProvider extends AppProvider {
  final ProductRepository _productRepository;

  // ----------- [Constructor] -----------
  ProductProvider(this._productRepository);
  // -------------------------------------

  // =========== [State] ===========
  final List<ProductModel> _products = [];
  final List<ProductModel> _topRateProducts = [];
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  // ===============================

  // =========== [Getter] ===========
  List<ProductModel> get products => _products;
  List<ProductModel> get topRateProducts => _topRateProducts;
  bool get hasMore => _hasMore;
  // ================================

  // ----------- [Functions] -----------
  Future<void> getProducts() async => execute(
    () async {
      // Pass page and limit to your repository (your backend will handle optional defaults)
      final response = await _productRepository.getProducts(
        page: _page,
        limit: _limit,
      );

      final newItems = response.data;

      // Append the new batch to the existing list
      _products.addAll(newItems);

      // Check if we've reached the end
      // If returned items are fewer than the limit
      if (newItems.length < _limit) {
        _hasMore = false;
      } else {
        _page++; // Increment page for the next scroll trigger
      }
    },
    onError: (error) => log("Error getProducts: $error"),
    onFinally: () => log('Finished getProducts()'),
  );

  Future<void> getTopRateProducts() async => execute(
    () async {},
    onError: (error) => log('Error getTopRateProducts: $error'),
    onFinally: () => log('Finish getTopRateProducts()'),
  );

  /// Reload the loaded products quietly (no spinner). Called by LiveUpdates.
  Future<void> refresh() async {
    if (isLoading || _products.isEmpty) return;
    final result = await reloadPages(
      loadedCount: _products.length,
      limit: _limit,
      fetch: (page) =>
          _productRepository.getProducts(page: page, limit: _limit),
    );
    if (isLoading) return;
    _products
      ..clear()
      ..addAll(result.items);
    _hasMore = result.hasNext;
    _page = result.hasNext ? result.pages + 1 : result.pages;
    notifyListeners();
  }
  // ------------------------------------
}
