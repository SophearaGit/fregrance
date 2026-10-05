import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../data/model/brand_model.dart';
import '../../domain/repository/brand_repository.dart';

final class BrandProvider extends AppProvider {
  final BrandRepository _repository;

  // ----------- [Constructor] -----------
  BrandProvider(this._repository);
  // -------------------------------------

  // =========== [State] ============
  List<BrandModel> _brands = [];
  final List<ProductModel> _brandProducts = [];

  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;

  String? _currentBrandName;
  // ================================

  // =========== [Getter] ============
  List<BrandModel> get brands => _brands;
  List<ProductModel> get brandProducts => _brandProducts;
  bool get hasMore => _hasMore;
  int get page => _page;
  // =================================

  // ----------- [Functions] -----------
  Future<void> getBrands() async => execute(
    () async {
      final response = await _repository.getBrands();
      _brands = response.data;
      notifyListeners();
    },
    // onError: (error) => log("getBrands Error.", error: error),
    // onFinally: () => log("End getBrands. _brands: $_brands"),
  );

  Future<void> getBrandProducts({
    required String name,
    int? page,
    int? limit,
  }) async {
    final targetPage = page ?? 1;
    final isFirstPage = targetPage == 1;
    final isNewBrand = _currentBrandName != name;

    // Reset when brand changes or first page
    if (isFirstPage || isNewBrand) {
      _brandProducts.clear();
      _page = 1;
      _hasMore = true;
      _currentBrandName = name;
      notifyListeners();
    }

    await execute(
      () async {
        final response = await _repository.getBrandProducts(
          name: name,
          page: page ?? targetPage,
          limit: limit ?? _limit,
        );

        final newItems = response.data;

        if (isFirstPage || isNewBrand) {
          _brandProducts
            ..clear()
            ..addAll(newItems);
        } else {
          _brandProducts.addAll(newItems);
        }

        _hasMore = response.pagination.hasNext;
        if (_hasMore) _page = targetPage + 1;

        notifyListeners();
      },
      // onError: (error) => log("getBrandProducts Error. $error"),
      // onFinally: () =>
      //     log("End getBrandProducts. _brandProducts: $_brandProducts"),
    );
  }

  // -----------------------------------
}
