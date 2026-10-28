import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../provider/favorite_provider.dart';

/// The perfumes the customer saved with the heart.
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => context.read<FavoriteProvider>().loadFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<FavoriteProvider>();
    final products = provider.products;

    Widget body;
    if (!AuthPreferences.isAuthenticated) {
      body = _Message(
        icon: Iconsax.heart,
        title: 'Sign in to keep your favorites',
        subtitle: 'Tap the heart on any perfume to save it here.',
        action: AppButton(
          'Sign in',
          width: 160,
          onTap: () => context.go(Routes.login),
        ),
      );
    } else if (provider.isLoading && products.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && products.isEmpty) {
      body = _Message(
        icon: Iconsax.warning_2,
        title: provider.error!,
        action: AppButton(
          'Try again',
          width: 160,
          onTap: provider.loadFavorites,
        ),
      );
    } else if (products.isEmpty) {
      body = _Message(
        icon: Iconsax.heart,
        title: 'No favorites yet',
        subtitle: 'Tap the heart on any perfume to save it here.',
        action: AppButton(
          'Explore perfumes',
          width: 190,
          onTap: () => context.go(Routes.main),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: provider.loadFavorites,
        child: Padding(
          padding: const EdgeInsets.all(AppConst.spaceMD),
          child: AppGridBuilder(
            items: products,
            itemBuilder: (context, product, _) =>
                ProductCard(key: ValueKey(product.id), product: product),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          products.isEmpty ? 'Favorites' : 'Favorites (${products.length})',
          style: textTheme.titleLarge,
        ),
        backgroundColor: colorScheme.surface,
        actions: const [AppCartCounter()],
      ),
      body: body,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppConst.spaceMD),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConst.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
