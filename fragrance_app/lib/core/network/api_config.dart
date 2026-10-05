import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  // Local PHP + MySQL backend served by Laragon (see fragrance_backend/README.md).
  // start-app.bat passes the real project folder name with --dart-define=API_PATH=...,
  // so this default is only used when the app is started some other way.
  static const String _path = String.fromEnvironment(
    'API_PATH',
    defaultValue: '/fregrance_all/fragrance_backend/api',
  );

  /// An Android emulator reaches this PC as 10.0.2.2; Chrome and Windows use localhost.
  static String get baseUrl {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return 'http://${isAndroid ? '10.0.2.2' : 'localhost'}$_path';
  }
}
