import 'dart:developer';

import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../data/favorite_remote_datasource.dart';

/// The products the customer saved with the heart button.
final class FavoriteProvider extends AppProvider {
  final FavoriteRemoteDatasource _datasource;

  FavoriteProvider(this._datasource);

  Set<String> _ids = {};
  List<ProductModel> _products = [];
  String? _idsFor; // the sign-in the ids belong to
  Future<void>? _idsLoading;
  final Set<String> _busy = {};

  List<ProductModel> get products => _products;

  /// True when the heart for [productId] should be filled.
  bool isFavorite(String productId) =>
      _idsFor == AuthPreferences.token && _ids.contains(productId);

  /// Fetch the ids once per sign-in (cheap; many hearts can call this).
  Future<void> ensureIds() {
    if (!AuthPreferences.isAuthenticated) return Future.value();
    if (_idsFor == AuthPreferences.token) return Future.value();
    return _idsLoading ??= _loadIds().whenComplete(() => _idsLoading = null);
  }

  Future<void> _loadIds() async {
    try {
      _ids = await _datasource.getIds();
      _idsFor = AuthPreferences.token;
      notifyListeners();
    } catch (error) {
      log('favorite ids error: $error');
    }
  }

  /// Load the full list for the Favorites screen.
  Future<void> loadFavorites() async => execute(
    () async {
      if (!AuthPreferences.isAuthenticated) {
        _products = [];
        return;
      }
      _products = await _datasource.getFavorites();
      _ids = {for (final product in _products) product.id};
      _idsFor = AuthPreferences.token;
    },
    onError: (Object error) {
      log('loadFavorites error: $error');
      setError(_friendly(error));
    },
  );

  /// Quiet reload when the admin changes products (photos, prices…).
  Future<void> refresh() async {
    if (_idsFor == null || isLoading || !AuthPreferences.isAuthenticated) {
      return;
    }
    try {
      _products = await _datasource.getFavorites();
      _ids = {for (final product in _products) product.id};
      notifyListeners();
    } catch (_) {}
  }

  /// Save or un-save. Returns null when it worked, otherwise the reason.
  Future<String?> toggle(ProductModel product) async {
    if (!AuthPreferences.isAuthenticated) {
      return 'Sign in to save your favorite scents.';
    }
    if (_busy.contains(product.id)) return null;
    await ensureIds();

    // Flip the heart straight away, then confirm with the shop.
    final wasFavorite = _ids.contains(product.id);
    _setLocal(product, !wasFavorite);
    _busy.add(product.id);
    try {
      final nowFavorite = await _datasource.toggle(product.id);
      _setLocal(product, nowFavorite);
      return null;
    } catch (error) {
      _setLocal(product, wasFavorite);
      return _friendly(error);
    } finally {
      _busy.remove(product.id);
    }
  }

  void _setLocal(ProductModel product, bool favorite) {
    if (favorite) {
      _ids.add(product.id);
      if (!_products.any((p) => p.id == product.id)) {
        _products = [product, ..._products];
      }
    } else {
      _ids.remove(product.id);
      _products = _products.where((p) => p.id != product.id).toList();
    }
    notifyListeners();
  }

  String _friendly(Object error) => error is ApiException
      ? error.message
      : 'Could not reach the shop. Is Laragon running?';
}
