import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/router/routes.dart';
import '../../features/cart/presentation/provider/cart_provider.dart';

class AppCartCounter extends StatelessWidget {
  const AppCartCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      onPressed: () => context.push(Routes.cart),
      icon: Badge(
        isLabelVisible: cartProvider.itemCount > 0,
        label: Text(cartProvider.itemCount.toString()),
        backgroundColor: colorScheme.primary,
        child: const Icon(Iconsax.shopping_bag),
      ),
    );
  }
}
