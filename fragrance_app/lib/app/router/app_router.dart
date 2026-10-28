import 'package:go_router/go_router.dart';

import '../../features/discovery/presentation/screens/discovery_products_screen.dart';
import 'routes.dart';
import '../../core/core.dart';

// App Level
import '../screens/error_screen.dart';
import '../screens/main_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';

// Branches Level
import '../../features/brand/presentation/screens/brand_screen.dart';
import '../../features/discovery/presentation/screens/discovery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';

// Sub Routes
import '../../features/brand/presentation/screens/brand_products_screen.dart';

// Full Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/favorite/presentation/screens/favorite_screen.dart';
import '../../features/product/presentation/screens/product_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/product/presentation/screens/search_screen.dart';
import '../../features/order/presentation/screens/my_orders_screen.dart';
import '../../features/address/data/model/address_model.dart';
import '../../features/address/presentation/screens/address_form_screen.dart';
import '../../features/address/presentation/screens/addresses_screen.dart';
import '../../features/order/presentation/screens/order_success_screen.dart';
import '../../features/order/presentation/screens/shipping_screen.dart';
import '../../features/review/presentation/screens/my_reviews_screen.dart';

// Model Parameter
import '../../features/product/data/model/product_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  errorBuilder: (context, state) => const ErrorScreen(),
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final String location = state.matchedLocation;
    final bool hasSeenOnboarding = AppPreferences.hasSeenOnboarding;

    // Splash always comes first.
    if (location == Routes.splash) return null;

    // Onboarding has not been completed yet.
    if (!hasSeenOnboarding) {
      return location == Routes.onboarding ? null : Routes.onboarding;
    }

    // Onboarding already completed.
    if (location == Routes.onboarding) return Routes.main;

    return null;
  },
  routes: [
    ...appRoutes, // App Level: Full Screen
    ...authRoutes, // Authentication Level: Full Screen
    ...branchRoutes, // Branches Level: Pin Bottom Navigation Menu
    ...fullScreens, // Full Screen Level
  ],
);

final List<RouteBase> appRoutes = [
  // App Level
  GoRoute(
    path: Routes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: Routes.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(path: Routes.error, builder: (context, state) => const ErrorScreen()),
  GoRoute(
    path: Routes.notfound,
    builder: (context, state) => const NotFoundScreen(),
  ),
];

final List<RouteBase> authRoutes = [
  GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
  GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
];

final List<RouteBase> branchRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return MainScreen(navigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.main,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.brand,
            builder: (context, state) => const BrandScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.discovery,
            builder: (context, state) => const DiscoveryScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.more,
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),
    ],
  ),
];

final List<RouteBase> fullScreens = [
  GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
  GoRoute(
    path: Routes.profileEdit,
    builder: (_, _) => const EditProfileScreen(),
  ),
  GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen()),
  GoRoute(path: Routes.orders, builder: (_, _) => const MyOrdersScreen()),
  GoRoute(path: Routes.shipping, builder: (_, _) => const ShippingScreen()),
  GoRoute(path: Routes.reviews, builder: (_, _) => const MyReviewsScreen()),
  GoRoute(
    path: Routes.addresses,
    builder: (context, state) =>
        AddressesScreen(pick: state.uri.queryParameters['pick'] == '1'),
  ),
  GoRoute(
    path: Routes.addressForm,
    builder: (context, state) =>
        AddressFormScreen(address: state.extra as AddressModel?),
  ),
  GoRoute(
    path: Routes.orderSuccess,
    builder: (context, state) =>
        OrderSuccessScreen(args: state.extra as OrderSuccessArgs),
  ),
  GoRoute(path: Routes.favorite, builder: (_, _) => const FavoriteScreen()),

  GoRoute(path: Routes.product, builder: (_, _) => const ProductScreen()),
  GoRoute(
    path: Routes.productDetail,
    builder: (context, state) {
      final product = state.extra as ProductModel;
      return ProductDetailScreen(product: product);
    },
  ),

  GoRoute(
    path: Routes.brandProducts,
    builder: (context, state) {
      final brandName = state.uri.queryParameters['name'] ?? '';
      return BrandProductsScreen(brandName: brandName);
    },
  ),

  GoRoute(
    path: Routes.discoveryProducts,
    builder: (context, state) => const DiscoveryProductsScreen(),
  ),

  GoRoute(
    path: Routes.search,
    builder: (context, state) =>
        SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
  ),
];
