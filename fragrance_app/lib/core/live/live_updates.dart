import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../network/api_response.dart';

/// Keeps the app in step with the admin site.
///
/// Every few seconds it asks the backend for a short fingerprint of the shop
/// data (GET /changes). When the fingerprint changes (a product, image or brand
/// was added, edited or deleted), it runs every refresher and tells its
/// listeners, so the screens update without the user pulling to refresh.
/// Checking stops while the app is in the background.
final class LiveUpdates extends ChangeNotifier {
  LiveUpdates(this._apiClient);

  final ApiClient _apiClient;

  static const Duration interval = Duration(seconds: 3);

  final List<Future<void> Function()> _refreshers = [];
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  String? _version;
  bool _checking = false;

  /// Start checking. [refreshers] run each time the data changes.
  void start(List<Future<void> Function()> refreshers) {
    _refreshers
      ..clear()
      ..addAll(refreshers);
    _lifecycle ??= AppLifecycleListener(onShow: _resume, onHide: _stopTimer);
    _resume();
  }

  void _resume() {
    _stopTimer();
    _timer = Timer.periodic(interval, (_) => unawaited(_check()));
    unawaited(_check());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final response = await _apiClient.get(path: '/changes');
      final body = response.data;
      final data = body?['data'];
      final version = data is Map<String, dynamic> ? data['version'] : null;
      if (version is! String) return;

      final changed = _version != null && _version != version;
      _version = version;
      if (!changed) return;

      log('LiveUpdates: data changed, refreshing screens');
      await Future.wait(_refreshers.map(_runQuietly));
      notifyListeners();
    } catch (_) {
      // Server not reachable right now (Laragon stopped?). Try again next tick.
    } finally {
      _checking = false;
    }
  }

  Future<void> _runQuietly(Future<void> Function() refresher) async {
    try {
      await refresher();
    } catch (error) {
      log('LiveUpdates: refresh failed: $error');
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _lifecycle?.dispose();
    super.dispose();
  }
}

/// Load pages 1, 2, ... again until at least [loadedCount] items are back
/// (always at least one page), and return them with the last page's hasNext.
/// Used to refresh a scrolled list without losing the user's place.
Future<({List<T> items, bool hasNext, int pages})> reloadPages<T>({
  required int loadedCount,
  required int limit,
  required Future<ApiPaginationResponse<List<T>>> Function(int page) fetch,
}) async {
  final pages = loadedCount <= limit ? 1 : (loadedCount + limit - 1) ~/ limit;
  final items = <T>[];
  var hasNext = false;
  for (var page = 1; page <= pages; page++) {
    final response = await fetch(page);
    items.addAll(response.data);
    hasNext = response.pagination.hasNext;
    if (!hasNext) {
      return (items: items, hasNext: false, pages: page);
    }
  }
  return (items: items, hasNext: hasNext, pages: pages);
}
