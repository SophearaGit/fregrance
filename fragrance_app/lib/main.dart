import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/providers/app_providers.dart';
import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStorage.init(); // Initialize Local Storage

  runApp(MultiProvider(providers: appProviders, child: const App()));
}
