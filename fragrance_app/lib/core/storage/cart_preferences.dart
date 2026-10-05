import 'package:shared_preferences/shared_preferences.dart';

abstract final class CartPreferences {
  static late SharedPreferences _prefs;
  static const _cartItems = 'cart_items';

  static Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  static List<String> get cart =>
      _prefs.getStringList(_cartItems) ?? const <String>[];

  static Future<void> setCartItems(List<String> value) =>
      _prefs.setStringList(_cartItems, value);

  static Future<void> clear() => _prefs.remove(_cartItems);
}
