import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static late SharedPreferences _prefs;
  static const _onBoardingKey = 'has_seen_onboarding';
  static const _themeKey = 'theme_mode';

  static Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  static bool get hasSeenOnboarding => _prefs.getBool(_onBoardingKey) ?? false;

  static Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_onBoardingKey, value);

  static bool get isDarkMode => _prefs.getBool(_themeKey) ?? false;

  static Future<void> setDarkMode(bool value) =>
      _prefs.setBool(_themeKey, value);
}
