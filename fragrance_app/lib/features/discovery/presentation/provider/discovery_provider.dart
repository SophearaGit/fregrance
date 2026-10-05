import 'dart:developer';

import '../../../../core/core.dart';
import '../../../product/data/model/fragrance_notes_model.dart';
import '../../../product/data/model/product_model.dart';
import '../../domain/repository/discovery_repository.dart';

final class DiscoveryProvider extends AppProvider {
  final DiscoveryRepository _repository;

  DiscoveryProvider(this._repository);

  // ── State ──────────────────────────────────────────────
  List<String> _moods = [];
  FragranceNotesModel? _notes;
  List<String> _occasions = [];
  List<String> _scentFamilies = [];
  List<ProductModel> _discoveryProducts = [];

  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingProducts = false;

  String? _selectedMood;
  String? _selectedNote;
  String? _selectedOccasion;
  String? _selectedScentFamily;
  String? _selectedType;

  // ── Getters ────────────────────────────────────────────
  List<String> get moods => _moods;
  FragranceNotesModel? get notes => _notes;
  List<String> get occasions => _occasions;
  List<String> get scentFamilies => _scentFamilies;
  List<ProductModel> get discoveryProducts => _discoveryProducts;

  bool get hasMore => _hasMore;
  bool get isLoadingProducts => _isLoadingProducts;

  String? get selectedMood => _selectedMood;
  String? get selectedNote => _selectedNote;
  String? get selectedOccasion => _selectedOccasion;
  String? get selectedScentFamily => _selectedScentFamily;
  String? get selectedType => _selectedType;

  bool get hasAnyFilter =>
      _selectedMood != null ||
      _selectedNote != null ||
      _selectedOccasion != null ||
      _selectedScentFamily != null ||
      _selectedType != null;

  // ── Fetch methods ──────────────────────────────────────
  Future<void> getMoods() async => execute(() async {
    final response = await _repository.getMoods();
    _moods = response.data;
    notifyListeners();
  }, onError: (error) => log('Moods Error: $error'));

  Future<void> getNotes() async => execute(() async {
    final response = await _repository.getNotes();
    _notes = response.data;
    notifyListeners();
  }, onError: (error) => log('Notes Error: $error'));

  Future<void> getOccasions() async => execute(() async {
    final response = await _repository.getOccasions();
    _occasions = response.data;
    notifyListeners();
  }, onError: (error) => log('Occasions Error: $error'));

  Future<void> getScentFamilies() async => execute(() async {
    final response = await _repository.getScentFamilies();
    _scentFamilies = response.data;
    notifyListeners();
  }, onError: (error) => log('Scent Families Error: $error'));

  // ── Selection / Filter methods ─────────────────────────
  void selectMood(String? mood) {
    _selectedMood = mood;
    _resetAndFetch();
  }

  void selectNote(String? note) {
    _selectedNote = note;
    _resetAndFetch();
  }

  void selectOccasion(String? occasion) {
    _selectedOccasion = occasion;
    _resetAndFetch();
  }

  void selectFamily(String? family) {
    _selectedScentFamily = family;
    _resetAndFetch();
  }

  void selectType(String? type) {
    _selectedType = type;
    _resetAndFetch();
  }

  void clearFilters() {
    _selectedMood = null;
    _selectedNote = null;
    _selectedOccasion = null;
    _selectedScentFamily = null;
    _selectedType = null;
    _resetAndFetch();
  }

  /// Used when entering DiscoveryProductsScreen
  void applyInitialFilters({
    String? mood,
    String? note,
    String? occasion,
    String? family,
    String? type,
  }) async {
    _selectedMood = mood;
    _selectedNote = note;
    _selectedOccasion = occasion;
    _selectedScentFamily = family;
    _selectedType = type;

    await getDiscoveryProducts();
  }

  // ── Products ───────────────────────────────────────────
  Future<void> getDiscoveryProducts({bool loadMore = false}) async {
    if (_isLoadingProducts) return;
    if (!loadMore) {
      _page = 1;
      _hasMore = true;
      _discoveryProducts = [];
    }
    if (!_hasMore && loadMore) return;

    _isLoadingProducts = true;
    notifyListeners();

    await execute(
      () async {
        final response = await _repository.getFilter(
          mood: _selectedMood,
          note: _selectedNote,
          occasion: _selectedOccasion,
          family: _selectedScentFamily,
          type: _selectedType,
          page: _page,
          limit: _limit,
        );

        final items = response.data;

        if (items.length < _limit) {
          _hasMore = false;
        }

        _discoveryProducts.addAll(items);
        _page++;
      },
      onError: (error) => log('Discovery Products Error: $error'),
      onFinally: () {
        _isLoadingProducts = false;
        notifyListeners();
      },
    );
  }

  void _resetAndFetch() async {
    notifyListeners();
    await getDiscoveryProducts();
  }
}
