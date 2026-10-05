import '../../app/providers/theme_provider.dart';

// -------------------- [Imports] --------------------
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repository/auth_repository_impl.dart';
import '../../features/auth/presentation/provider/auth_provider.dart';

import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repository/profile_repository_impl.dart';
import '../../features/profile/presentation/provider/profile_provider.dart';

import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repository/product_repository_impl.dart';
import '../../features/product/presentation/provider/product_provider.dart';

import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/repository/cart_repository_impl.dart';
import '../../features/cart/presentation/provider/cart_provider.dart';

import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repository/home_repository_impl.dart';
import '../../features/home/presentation/provider/home_provider.dart';

import '../../features/brand/data/datasources/brand_remote_datasource.dart';
import '../../features/brand/data/repository/brand_repository_impl.dart';
import '../../features/brand/presentation/provider/brand_provider.dart';

import '../../features/discovery/data/datasources/discovery_remote_datasource.dart';
import '../../features/discovery/data/repository/discovery_repository_impl.dart';
import '../../features/discovery/presentation/provider/discovery_provider.dart';
// ---------------------------------------------------

// dart format off
// ~~~~~~~~~~~~~~~~~~ [Injections] ~~~~~~~~~~~~~~~~~~~
import '../network/api_client.dart';

final apiClient = ApiClient();


// ======================[Theme]=====================
final themeProvider = ThemeProvider();
// ==================================================

// ======================[Auth]======================
final authDatasource  = AuthRemoteDatasourceImpl(apiClient);
final authRepository  = AuthRepositoryImpl(authDatasource);
final authProvider    = AuthProvider(authRepository);
// ==================================================

// ==================[Profile/User]==================
final profileDatasource = ProfileRemoteDatasourceImpl(apiClient);
final profileRepository = ProfileRepositoryImpl(profileDatasource);
final profileProvider   = ProfileProvider(profileRepository);
// ==================================================

// ====================[Product]=====================
final productDatasource = ProductRemoteDatasourceImpl(apiClient);
final productRepository = ProductRepositoryImpl(productDatasource);
final productProvider   = ProductProvider(productRepository);
// ==================================================

// ====================[Cart]========================
final cartDatasource  = CartRemoteDatasourceImpl(apiClient);
final cartRepository  = CartRepositoryImpl(cartDatasource);
final cartProvider    = CartProvider(cartRepository);
// ==================================================

// ====================[Home]========================
final homeDatasource  = HomeRemoteDatasourceImpl(apiClient);
final homeRepository  = HomeRepositoryImpl(homeDatasource);
final homeProvider    = HomeProvider(homeRepository);
// ==================================================

// ====================[Brand]=======================
final brandDatasource = BrandRemoteDatasourceImpl(apiClient);
final brandRepository = BrandRepositoryImpl(brandDatasource);
final brandProvider   = BrandProvider(brandRepository);
// ==================================================

// ====================[Discovery]===================
final discoveryDatasource = DiscoveryRemoteDatasourceImpl(apiClient);
final discoveryRepository = DiscoveryRepositoryImpl(discoveryDatasource);
final discoveryProvider   = DiscoveryProvider(discoveryRepository);
// ==================================================
