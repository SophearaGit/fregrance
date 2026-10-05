import 'package:shared_preferences/shared_preferences.dart';

abstract final class AuthPreferences {
  static late SharedPreferences _prefs;
  static const _authToken = 'auth_token';

  static Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  static String? get token => _prefs.getString(_authToken);

  static Future<void> setToken(String token) =>
      _prefs.setString('auth_token', token);

  static Future<void> clear() => _prefs.remove(_authToken);

  static bool get isAuthenticated => token != null;
}
