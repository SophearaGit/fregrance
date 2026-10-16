import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../provider/brand_provider.dart';
import 'brand_card.dart';

class BrandGridLayout extends StatelessWidget {
  const BrandGridLayout({super.key, this.query = ''});

  /// Words typed in the Houses search box; only matching brands are shown.
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final provider = context.watch<BrandProvider>();
    final words = query.trim().toLowerCase();
    final brands = words.isEmpty
        ? provider.brands
        : provider.brands
              .where((brand) => brand.brand.toLowerCase().contains(words))
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Brands', style: textTheme.titleMedium),
        const SizedBox(height: AppConst.spaceMD),
        if (words.isNotEmpty && brands.isEmpty)
          Text(
            'No houses match "${query.trim()}".',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        AppGridBuilder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          items: brands,
          itemBuilder: (context, brand, index) {
            return BrandCard(
              brand: brand,
              onTap: () =>
                  context.push(Routes.brandProductsPath(name: brand.brand)),
            );
          },
        ),
      ],
    );
  }
}
