import '../../../../core/core.dart';
import '../../../product/data/model/product_model.dart';
import '../../data/model/featured_model.dart';
import '../../domain/repository/home_repository.dart';

final class HomeProvider extends AppProvider {
  final HomeRepository _repository;

  // ----------- [Constructor] -----------
  HomeProvider(this._repository);
  // -------------------------------------

  // =========== [State] ============
  int _page = 1;
  final int _limit = 10;

  final List<ProductModel> _feeds = [];
  FeaturedModel? _featured;
  String _currentTab = 'All';
  bool _hasMore = true;

  // =================================

  // =========== [Getter] ============
  List<ProductModel> get feeds => _feeds;
  FeaturedModel? get featured => _featured;
  String get currentTab => _currentTab;
  bool get hasMore => _hasMore;

  // =================================

  // ----------- [Functions] -----------
  Future<void> getFeed({String? tab, int? page, int? limit}) async {
    final targetTab = tab ?? _currentTab;
    final bool isTabChanged = tab != null && tab != _currentTab;

    if (isTabChanged) {
      _currentTab = targetTab;
      _page = 1;
      notifyListeners();
    }

    await execute(() async {
      final response = await _repository.getFeed(
        tab: tab,
        page: page ?? _page,
        limit: limit ?? _limit,
      );

      if (isTabChanged) _feeds.clear();

      final newIems = response.data;
      _feeds.addAll(newIems);
      _hasMore = response.pagination.hasNext;
      if (_hasMore) _page++;
    });
  }

  Future<void> getFeatured() async => execute(() async {
    final response = await _repository.getFeatured();
    _featured = response.data;
    notifyListeners(); // Refresh UI
  });
  // -------------------------------------
}
