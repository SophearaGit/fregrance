import 'package:flutter/material.dart';

import '../../core/core.dart';

final class ThemeProvider extends AppProvider {
  ThemeMode get themeMode =>
      AppPreferences.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  bool get isDarkMode => AppPreferences.isDarkMode;

  Future<void> toggleTheme() =>
      execute(() async => await AppPreferences.setDarkMode(!isDarkMode));
}
