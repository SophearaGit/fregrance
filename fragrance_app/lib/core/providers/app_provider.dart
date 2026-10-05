import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  @protected
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @protected
  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @protected
  void clearError() => _error = null;

  Future<T?> execute<T>(
    Future<T> Function() action, {
    void Function(Object error)? onError,
    FutureOr<void> Function()? onFinally,
  }) async {
    setLoading(true);
    clearError();

    try {
      return await action();
    } catch (error) {
      onError != null ? onError(error) : setError(error.toString());
      return null;
    } finally {
      setLoading(false);
      if (onFinally != null) await onFinally();
    }
  }
}
