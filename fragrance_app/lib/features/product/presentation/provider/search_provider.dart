import 'dart:async';
import 'dart:developer';

import '../../../../core/live/live_updates.dart';
import '../../../../core/providers/app_provider.dart';
import '../../data/model/product_model.dart';
import '../../domain/repository/product_repository.dart';

/// Product search: waits until typing pauses, then asks the API
/// (GET /product?search=...) and keeps the results page by page.
final class SearchProvider extends AppProvider {
  final ProductRepository _productRepository;

  // ----------- [Constructor] -----------
  SearchProvider(this._productRepository);
  // -------------------------------------

  // =========== [State] ===========
  static const Duration _debounce = Duration(milliseconds: 400);
  final int _limit = 20;

  final List<ProductModel> _results = [];
  String _query = '';
  int _page = 1;
  bool _hasMore = false;
  bool _hasSearched = false;
  int _requestId = 0; // only the newest search may change the results
  Timer? _timer;
  // ===============================

  // =========== [Getter] ===========
  List<ProductModel> get results => _results;
  String get query => _query;
  bool get hasMore => _hasMore;

  /// True once the search for the current words has come back.
  bool get hasSearched => _hasSearched;
  // ================================

  // ----------- [Functions] -----------
  /// Call on every keystroke.
  void onQueryChanged(String value) {
    final text = value.trim();
    if (text == _query) return;

    _timer?.cancel();
    _query = text;
    _hasSearched = false;

    if (text.isEmpty) {
      _requestId++; // ignore a search that is still on its way
      _results.clear();
      _hasMore = false;
      notifyListeners();
      return;
    }

    notifyListeners();
    _timer = Timer(_debounce, () => unawaited(_search(reset: true)));
  }

  /// Search straight away, for the keyboard's search button.
  Future<void> searchNow(String value) async {
    _timer?.cancel();
    _query = value.trim();
    if (_query.isEmpty) return;
    await _search(reset: true);
  }

  /// Next page of results, used while scrolling.
  Future<void> loadMore() async {
    if (isLoading || !_hasMore || _query.isEmpty) return;
    await _search(reset: false);
  }

  /// Start fresh, used when the search screen opens.
  void clear() {
    _timer?.cancel();
    _requestId++;
    _query = '';
    _results.clear();
    _page = 1;
    _hasMore = false;
    _hasSearched = false;
    clearError();
    notifyListeners();
  }

  /// Run the current search again quietly. Called by LiveUpdates.
  Future<void> refresh() async {
    if (isLoading || !_hasSearched || _query.isEmpty) return;
    final requestId = _requestId;
    final query = _query;

    final result = await reloadPages(
      loadedCount: _results.length,
      limit: _limit,
      fetch: (page) => _productRepository.getProducts(
        page: page,
        limit: _limit,
        search: query,
      ),
    );
    if (requestId != _requestId || query != _query) return;

    _results
      ..clear()
      ..addAll(result.items);
    _hasMore = result.hasNext;
    _page = result.pages + 1;
    notifyListeners();
  }

  Future<void> _search({required bool reset}) async {
    final requestId = ++_requestId;
    final query = _query;
    final page = reset ? 1 : _page;

    await execute(
      () async {
        final response = await _productRepository.getProducts(
          page: page,
          limit: _limit,
          search: query,
        );
        if (requestId != _requestId) return; // a newer search took over

        if (reset) _results.clear();
        _results.addAll(response.data);
        _hasMore = response.pagination.hasNext;
        _page = page + 1;
        _hasSearched = true;
      },
      onError: (error) {
        log('Error search "$query": $error');
        if (requestId != _requestId) return;
        if (reset) _results.clear();
        _hasMore = false;
        _hasSearched = true;
        setError(error.toString());
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------------------------------------
}
