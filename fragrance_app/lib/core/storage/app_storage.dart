import '../core.dart';

abstract final class AppStorage {
  static Future<void> init() async {
    await AppPreferences.init();
    await AuthPreferences.init();
    await CartPreferences.init();
  }
}
