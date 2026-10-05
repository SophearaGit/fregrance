import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/core.dart';

final List<SingleChildWidget> appProviders = [
  Provider.value(value: apiClient),

  // ======================[ Auth ]=======================
  ChangeNotifierProvider.value(value: themeProvider),

  // ======================[ Auth ]=======================
  ChangeNotifierProvider.value(value: authProvider),

  // ====================[ Product ]====================
  ChangeNotifierProvider.value(value: productProvider),

  // =====================[ Cart ]======================
  ChangeNotifierProvider.value(value: cartProvider),

  // =================[ Profile/User ]==================
  ChangeNotifierProvider.value(value: profileProvider),

  // =====================[ Home ]======================
  ChangeNotifierProvider.value(value: homeProvider),

  // =====================[ Brand ]=====================
  ChangeNotifierProvider.value(value: brandProvider),

  // ===================[ Discovery ]===================
  ChangeNotifierProvider.value(value: discoveryProvider),
];
