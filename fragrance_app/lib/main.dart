import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/providers/app_providers.dart';
import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStorage.init(); // Initialize Local Storage

  // Load the saved cart now so the cart badge is right on every screen.
  unawaited(cartProvider.loadCart());
  // Signed in from last time: load the name, photo and wallet for the More tab.
  unawaited(profileProvider.getProfile());

  // Show admin-site changes (new images, prices, products) without a manual refresh.
  liveUpdates.start([
    homeProvider.refresh,
    productProvider.refresh,
    brandProvider.refresh,
    discoveryProvider.refresh,
    searchProvider.refresh,
    cartProvider.refresh,
    orderProvider.refresh,
  ]);

  runApp(MultiProvider(providers: appProviders, child: const App()));
}
