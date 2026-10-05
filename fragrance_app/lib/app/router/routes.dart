abstract final class Routes {
  // ==========================================
  // App Level Routes
  // ==========================================
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String error = '/error';
  static const String notfound = '/notfound';
  static const String main = '/main';

  // ==========================================
  // Separate/Full Screen
  // ==========================================
  static const String login = '/login';
  static const String register = '/register';
  static const String favorite = "/favorite";
  static const String profile = '/profile';

  // ==========================================
  // Bottom Navigation Level Routes
  // ==========================================
  static const String home = "/home";
  static const String discovery = "/discovery";
  static const String brand = "/brand";
  static const String more = '/more';

  // ==========================================
  // Nested Routes
  // ==========================================
  // Base Route
  static const String brandProducts = '/brand/products';
  // Parameterized Route (Helper)
  static String brandProductsPath({required String name}) =>
      Uri(path: brandProducts, queryParameters: {'name': name}).toString();

  // ==========================================
  // Full Screen Level Routes
  // ==========================================
  static const String product = "/product";
  static const String productDetail = "/product/detail";

  static const String cart = '/cart';

  static const String discoveryProducts = '/discovery/products';
}
